// The shell and MicroPython run synchronously in the same PSC-OS process.
// Use the existing SD syscalls, and the SAME first MBR partition as fat32.c.
#include <stdint.h>
#include "py/runtime.h"
#include "py/mperrno.h"
#include "extmod/vfs.h"
#include "psc_vfs.h"

// user.h defines its own bool/stdio types; keep those out of MicroPython.
extern int call_sd_read_buf_api(uint32_t sector, void *buf);
extern uint32_t call_sd_write_buf_api(uint32_t sector, const uint8_t *buf);

typedef struct {
    mp_obj_base_t base;
    uint32_t start, count;
    bool write_error;
} psc_sd_t;

static uint32_t le32(const uint8_t *p) {
    return (uint32_t)p[0] | (uint32_t)p[1] << 8 |
        (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24;
}

static mp_obj_t sd_transfer(mp_obj_t self_in, mp_obj_t block_in,
    mp_obj_t buffer, bool write) {
    psc_sd_t *self = MP_OBJ_TO_PTR(self_in);
    if (self->write_error) {
        mp_raise_OSError(MP_EIO);
    }
    mp_int_t block = mp_obj_get_int(block_in);
    mp_buffer_info_t buf;
    mp_get_buffer_raise(buffer, &buf, write ? MP_BUFFER_READ : MP_BUFFER_WRITE);
    size_t count = buf.len / 512;
    if (block < 0 || buf.len % 512 || (uint32_t)block >= self->count ||
        count > self->count - (uint32_t)block) {
        return MP_OBJ_NEW_SMALL_INT(-MP_EINVAL);
    }
    for (size_t i = 0; i < count; ++i) {
        uint32_t lba = self->start + (uint32_t)block + i;
        uint8_t *p = (uint8_t *)buf.buf + i * 512;
        int result = write ? (int)call_sd_write_buf_api(lba, p) :
            call_sd_read_buf_api(lba, p);
        if (result) {
            // FatFs/VfsFat ignore some I/O return values (directory iteration,
            // seek, FAT mirror and FSInfo). Raise at the boundary so failures
            // cannot look like EOF or success. LFN buffers are on the stack
            // and FatFs has no locks to unwind.
            if (write) {
                // A partially written volume must be remounted after reset.
                self->write_error = true;
            }
            mp_raise_OSError(MP_EIO);
        }
    }
    return MP_OBJ_NEW_SMALL_INT(0);
}

static mp_obj_t sd_readblocks(mp_obj_t self, mp_obj_t block, mp_obj_t buf) {
    return sd_transfer(self, block, buf, false);
}
static MP_DEFINE_CONST_FUN_OBJ_3(sd_readblocks_obj, sd_readblocks);

static mp_obj_t sd_writeblocks(mp_obj_t self, mp_obj_t block, mp_obj_t buf) {
    return sd_transfer(self, block, buf, true);
}
static MP_DEFINE_CONST_FUN_OBJ_3(sd_writeblocks_obj, sd_writeblocks);

static mp_obj_t sd_ioctl(mp_obj_t self_in, mp_obj_t command, mp_obj_t arg) {
    (void)arg;
    psc_sd_t *self = MP_OBJ_TO_PTR(self_in);
    if (self->write_error) {
        mp_raise_OSError(MP_EIO);
    }
    switch (mp_obj_get_int(command)) {
        case MP_BLOCKDEV_IOCTL_INIT:
        case MP_BLOCKDEV_IOCTL_DEINIT:
        case MP_BLOCKDEV_IOCTL_SYNC:
            // Each write syscall waits for completion and verifies the sector.
            return MP_OBJ_NEW_SMALL_INT(0);
        case MP_BLOCKDEV_IOCTL_BLOCK_COUNT:
            return mp_obj_new_int_from_uint(self->count);
        case MP_BLOCKDEV_IOCTL_BLOCK_SIZE:
            return MP_OBJ_NEW_SMALL_INT(512);
        default:
            return mp_const_none;
    }
}
static MP_DEFINE_CONST_FUN_OBJ_3(sd_ioctl_obj, sd_ioctl);

static const mp_rom_map_elem_t sd_locals_table[] = {
    { MP_ROM_QSTR(MP_QSTR_readblocks), MP_ROM_PTR(&sd_readblocks_obj) },
    { MP_ROM_QSTR(MP_QSTR_writeblocks), MP_ROM_PTR(&sd_writeblocks_obj) },
    { MP_ROM_QSTR(MP_QSTR_ioctl), MP_ROM_PTR(&sd_ioctl_obj) },
};
static MP_DEFINE_CONST_DICT(sd_locals, sd_locals_table);
static MP_DEFINE_CONST_OBJ_TYPE(psc_sd_type, MP_QSTR_SDCard, MP_TYPE_FLAG_NONE,
    locals_dict, &sd_locals);

static mp_obj_t psc_mount_sd(void) {
    // Never replace an active mount: open files can still refer to it.
    if (MP_STATE_VM(vfs_mount_table) != NULL) {
        mp_raise_OSError(MP_EBUSY);
    }
    uint8_t sector[512];
    if (call_sd_read_buf_api(0, sector)) {
        mp_raise_OSError(MP_ENODEV);
    }
    uint32_t start = le32(sector + 0x1c6);
    uint32_t count = le32(sector + 0x1ca);
    // PSC-OS uses partition #1; never silently select another partition.
    if (sector[510] != 0x55 || sector[511] != 0xaa || !start || !count ||
        count > UINT32_MAX - start) {
        mp_raise_OSError(MP_ENODEV);
    }
    if (call_sd_read_buf_api(start, sector)) {
        mp_raise_OSError(MP_EIO);
    }
    // Require a 512-byte FAT32 BPB. FatFs validates the remaining geometry.
    uint32_t total = le32(sector + 32);
    if (sector[510] != 0x55 || sector[511] != 0xaa ||
        sector[11] != 0 || sector[12] != 2 || sector[17] || sector[18] ||
        sector[22] || sector[23] || !le32(sector + 36) || !total || total > count) {
        mp_raise_OSError(MP_ENODEV);
    }
    psc_sd_t *sd = mp_obj_malloc(psc_sd_t, &psc_sd_type);
    sd->start = start;
    sd->count = total;
    sd->write_error = false;
    mp_obj_t args[] = { MP_OBJ_FROM_PTR(sd), MP_OBJ_NEW_QSTR(MP_QSTR__slash_) };
    mp_map_t kwargs;
    mp_map_init_fixed_table(&kwargs, 0, NULL);
    mp_vfs_mount(2, args, &kwargs); // mkfs defaults to false; never format.
    mp_vfs_chdir(args[1]);
    return mp_const_none;
}
MP_DEFINE_CONST_FUN_OBJ_0(psc_mount_sd_obj, psc_mount_sd);

void psc_vfs_init(void) {
    nlr_buf_t nlr;
    if (nlr_push(&nlr) == 0) {
        psc_mount_sd();
        nlr_pop();
    } else {
        // No card/bad filesystem must not prevent entering Raw REPL.
        // The unmounted VFS raises ENODEV for open(); psc.mount_sd() retries
        // explicitly and reports the mount error to the caller.
        if (!mp_obj_exception_match(MP_OBJ_FROM_PTR(nlr.ret_val), MP_OBJ_FROM_PTR(&mp_type_OSError))) {
            nlr_raise(nlr.ret_val);
        }
    }
}
