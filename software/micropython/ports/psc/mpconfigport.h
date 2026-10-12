#include <stdint.h>

// options to control how MicroPython is built

// Use the minimal starting configuration (disables all optional features).
#define MICROPY_CONFIG_ROM_LEVEL (MICROPY_CONFIG_ROM_LEVEL_MINIMUM)

// You can disable the built-in MicroPython compiler by setting the following
// config option to 0.  If you do this then you won't get a REPL prompt, but you
// will still be able to execute pre-compiled scripts, compiled with mpy-cross.
#define MICROPY_ENABLE_COMPILER     (1)

#define MICROPY_QSTR_EXTRA_POOL           mp_qstr_frozen_const_pool
#define MICROPY_ENABLE_GC                 (1)
#define MICROPY_HELPER_REPL               (1)
#define MICROPY_MODULE_FROZEN_MPY         (1)
#define MICROPY_ENABLE_EXTERNAL_IMPORT    (1)

#define MICROPY_PY_BUILTINS_DIR (1)

// sin, cos support
#define MICROPY_PY_MATH     (1)
#define MICROPY_FLOAT_IMPL  MICROPY_FLOAT_IMPL_FLOAT

#define MICROPY_ALLOC_PATH_MAX            (256)

// Use the minimum headroom in the chunk allocator for parse nodes.
#define MICROPY_ALLOC_PARSE_CHUNK_INIT    (16)

// Keep IDE path/argv discovery; shell exit is explicitly psc.exit().
#define MICROPY_PY_SYS_MODULES            (0)
#define MICROPY_PY_SYS_EXIT               (0)
#define MICROPY_PY_SYS_PATH               (1)
#define MICROPY_PY_SYS_ARGV               (1)

// type definitions for the specific machine

typedef long mp_off_t;

// We need to provide a declaration/definition of alloca()

#define MICROPY_HW_BOARD_NAME "PSC-ONE"
#define MICROPY_HW_MCU_NAME "RV32IM"

#if defined(__linux__) || defined(__APPLE__)
#define MICROPY_MIN_USE_STDOUT (1)
#define MICROPY_HEAP_SIZE      (25600)
#endif

#ifdef __thumb__
#define MICROPY_MIN_USE_CORTEX_CPU (0)
#define MICROPY_MIN_USE_STM32_MCU (0)
#define MICROPY_HEAP_SIZE      (2048)
#endif

#if defined(__riscv)
#define MICROPY_HEAP_SIZE      (128 * 1024)
#endif

#define MP_STATE_PORT MP_STATE_VM

#ifndef alloca
#define alloca(size) __builtin_alloca(size)
#endif

// Standard blocking friendly/raw/raw-paste REPL, with a 128-byte paste window.
#define MICROPY_REPL_EVENT_DRIVEN (0)
#define MICROPY_REPL_STDIN_BUFFER_MAX (256)
#define MICROPY_KBD_EXCEPTION (1)
void psc_mp_poll(void);
#define MICROPY_VM_HOOK_LOOP psc_mp_poll();
#define MICROPY_EVENT_POLL_HOOK do { psc_mp_poll(); mp_handle_pending(MP_HANDLE_PENDING_CALLBACKS_AND_EXCEPTIONS); } while (0);
#define MICROPY_PY_SYS_PLATFORM "psc"
#define MICROPY_PY_SYS_STDFILES (1)
#define MICROPY_PY_SYS_STDIO_BUFFER (1)
#define MICROPY_PY_IO (1)
#define MICROPY_PY_GC (1)
#define MICROPY_PY_BUILTINS_INPUT (1)
#define MICROPY_PY_BUILTINS_HELP (1)
#define MICROPY_PY_BUILTINS_HELP_MODULES (1)
#define MICROPY_PY_BUILTINS_STR_OP_MODULO (1)
#define MICROPY_PY_BUILTINS_SLICE (1)
// Mount PSC-OS's first FAT32 partition at / using its SD sector syscalls.
#define MICROPY_VFS (1)
#define MICROPY_VFS_WRITABLE (1)
#define MICROPY_VFS_FAT (1)
#define MICROPY_ENABLE_FINALISER (1)
#define MICROPY_PY_BUILTINS_BYTEARRAY (1)
// FAT timestamps and SD/file sizes exceed the RV32 tagged small-int range.
#define MICROPY_LONGINT_IMPL (MICROPY_LONGINT_IMPL_LONGLONG)
#define MICROPY_FATFS_ENABLE_LFN (2)
#define MICROPY_FATFS_RPATH (2)
#define MICROPY_FATFS_NORTC (1)
#define MICROPY_READER_VFS (1)
#define MICROPY_PY_OS (1)
#define MICROPY_PY_OS_STATVFS (1)
