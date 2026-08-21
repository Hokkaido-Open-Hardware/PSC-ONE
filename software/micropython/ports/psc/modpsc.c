#include "py/obj.h"
#include "py/runtime.h"
#include "py/compile.h"
#include "py/repl.h"
#include "py/mperrno.h"

/*
 * PSC-OS側にある関数。
 * 最終的に shell.elf へ一緒にリンクされるので、
 * MicroPython側から外部関数として呼び出す。
 */
extern void fat32_ls(void);
extern int fat32_read(
    const char *name,
    uint8_t *dst,
    uint32_t max_size,
    uint32_t *read_size
);
extern void do_str(const char *src, mp_parse_input_kind_t input_kind);


/* Python: psc.fat32_ls() */
static mp_obj_t psc_fat32_ls(void)
{
    fat32_ls();

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_fat32_ls_obj,
    psc_fat32_ls
);


#define PSC_PY_MAX_SIZE (4 * 1024)

/* Python: psc.run("TEST.PY") */
static mp_obj_t psc_run(mp_obj_t filename_obj)
{
    const char *filename = mp_obj_str_get_str(filename_obj);

    /*
     * staticにしてuser stackを消費しないようにする。
     * fat32_read()側が複数sector/FAT chain対応なら、
     * 最大4KBのPython scriptを読み込める。
     */
    static uint8_t buf[PSC_PY_MAX_SIZE + 1];
    uint32_t size = 0;

    if (fat32_read(
            filename,
            buf,
            PSC_PY_MAX_SIZE,
            &size) != 0) {
        mp_raise_OSError(MP_ENOENT);
    }

    if (size > PSC_PY_MAX_SIZE) {
        mp_raise_ValueError(MP_ERROR_TEXT("script too large"));
    }

    buf[size] = '\0';

    do_str(
        (const char *)buf,
        MP_PARSE_FILE_INPUT
    );

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_run_obj,
    psc_run
);


/* psc module globals */
static const mp_rom_map_elem_t psc_module_globals_table[] = {
    {
        MP_ROM_QSTR(MP_QSTR___name__),
        MP_ROM_QSTR(MP_QSTR_psc)
    },
    {
        MP_ROM_QSTR(MP_QSTR_fat32_ls),
        MP_ROM_PTR(&psc_fat32_ls_obj)
    },
    {
        MP_ROM_QSTR(MP_QSTR_run),
        MP_ROM_PTR(&psc_run_obj)
    },
};

static MP_DEFINE_CONST_DICT(
    psc_module_globals,
    psc_module_globals_table
);


/* module definition */
const mp_obj_module_t psc_module = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&psc_module_globals,
};


/* import psc で使えるように登録 */
MP_REGISTER_MODULE(MP_QSTR_psc, psc_module);