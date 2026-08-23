#include "py/obj.h"
#include "py/runtime.h"
#include "py/compile.h"
#include "py/repl.h"
#include "py/mperrno.h"

#include "mphalport.h"


/* ------------------------------------------------------------
 * PSC-OS側関数
 * ------------------------------------------------------------ */

extern void fat32_ls(void);

extern int fat32_read(
    const char *name,
    uint8_t *dst,
    uint32_t max_size,
    uint32_t *read_size
);

extern void do_str(
    const char *src,
    mp_parse_input_kind_t input_kind
);


/* ------------------------------------------------------------
 * FAT32
 * ------------------------------------------------------------ */

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


/* ------------------------------------------------------------
 * Pythonスクリプト実行
 * ------------------------------------------------------------ */

#define PSC_PY_MAX_SIZE (4u * 1024u)

/* Python: psc.run("TEST.PY") */
static mp_obj_t psc_run(mp_obj_t filename_obj)
{
    const char *filename =
        mp_obj_str_get_str(filename_obj);

    /*
     * user stackを消費しないようstatic領域を使用する。
     * 最大4KBのPythonスクリプトを読み込む。
     */
    static uint8_t buf[PSC_PY_MAX_SIZE + 1u];
    uint32_t size = 0;

    if (fat32_read(
            filename,
            buf,
            PSC_PY_MAX_SIZE,
            &size) != 0) {

        mp_raise_OSError(MP_ENOENT);
    }

    if (size > PSC_PY_MAX_SIZE) {
        mp_raise_ValueError(
            MP_ERROR_TEXT("script too large")
        );
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


/* ------------------------------------------------------------
 * TIMER
 * ------------------------------------------------------------ */

/* Python: psc.timer_start(count) */
static mp_obj_t psc_timer_start(mp_obj_t count_obj)
{
    uint32_t count =
        (uint32_t)mp_obj_get_int(count_obj);

    psc_timer_start_api(count);

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_timer_start_obj,
    psc_timer_start
);


/* Python: psc.timer_start_auto(count) */
static mp_obj_t psc_timer_start_auto(mp_obj_t count_obj)
{
    uint32_t count =
        (uint32_t)mp_obj_get_int(count_obj);

    psc_timer_start_auto_api(count);

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_timer_start_auto_obj,
    psc_timer_start_auto
);

/* Python: psc.timer_stop() */
static mp_obj_t psc_timer_stop(void)
{
    psc_timer_stop_api();

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_timer_stop_obj,
    psc_timer_stop
);


/* Python: psc.timer_count() */
static mp_obj_t psc_timer_count(void)
{
    return mp_obj_new_int_from_uint(
        psc_timer_get_count_api()
    );
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_timer_count_obj,
    psc_timer_count
);


/* Python: psc.timer_status() */
static mp_obj_t psc_timer_status(void)
{
    return mp_obj_new_int_from_uint(
        psc_timer_get_status_api()
    );
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_timer_status_obj,
    psc_timer_status
);


/* Python: psc.timer_running() */
static mp_obj_t psc_timer_running(void)
{
    return mp_obj_new_bool(
        psc_timer_is_running_api() != 0
    );
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_timer_running_obj,
    psc_timer_running
);




/* Python: psc.wait_us(us) */
static mp_obj_t psc_wait_us(mp_obj_t us_obj)
{
    uint32_t us =
        (uint32_t)mp_obj_get_int(us_obj);

    psc_timer_wait_us_api(us);

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_wait_us_obj,
    psc_wait_us
);


/* Python: psc.wait_ms(ms) */
static mp_obj_t psc_wait_ms(mp_obj_t ms_obj)
{
    uint32_t ms =
        (uint32_t)mp_obj_get_int(ms_obj);

    psc_timer_wait_ms_api(ms);

    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_wait_ms_obj,
    psc_wait_ms
);



/* ------------------------------------------------------------
 * LED
 * ------------------------------------------------------------ */

/* Python: psc.led_write(value) */
static mp_obj_t psc_led_write(mp_obj_t value_obj)
{
    uint32_t value = (uint32_t)mp_obj_get_int(value_obj);
    psc_led_write_api(value);
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_led_write_obj,
    psc_led_write
);


/* Python: psc.led_on(led) */
static mp_obj_t psc_led_on(mp_obj_t led_obj)
{
    uint32_t led = (uint32_t)mp_obj_get_int(led_obj);
    psc_led_on_api(led);
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_led_on_obj,
    psc_led_on
);


/* Python: psc.led_off(led) */
static mp_obj_t psc_led_off(mp_obj_t led_obj)
{
    uint32_t led = (uint32_t)mp_obj_get_int(led_obj);
    psc_led_off_api(led);
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_led_off_obj,
    psc_led_off
);


/* Python: psc.led_toggle(led) */
static mp_obj_t psc_led_toggle(mp_obj_t led_obj)
{
    uint32_t led = (uint32_t)mp_obj_get_int(led_obj);
    psc_led_toggle_api(led);
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_1(
    psc_led_toggle_obj,
    psc_led_toggle
);


/* Python: psc.led_all_on() */
static mp_obj_t psc_led_all_on(void)
{
    psc_led_all_on_api();
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_led_all_on_obj,
    psc_led_all_on
);


/* Python: psc.led_all_off() */
static mp_obj_t psc_led_all_off(void)
{
    psc_led_all_off_api();
    return mp_const_none;
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_led_all_off_obj,
    psc_led_all_off
);


/* Python: psc.led_state() */
static mp_obj_t psc_led_state(void)
{
    return mp_obj_new_int_from_uint(
        psc_led_get_state_api()
    );
}

static MP_DEFINE_CONST_FUN_OBJ_0(
    psc_led_state_obj,
    psc_led_state
);


/* ------------------------------------------------------------
 * psc module globals
 * ------------------------------------------------------------ */

static const mp_rom_map_elem_t psc_module_globals_table[] = {

    {
        MP_ROM_QSTR(MP_QSTR___name__),
        MP_ROM_QSTR(MP_QSTR_psc)
    },

    /* FAT32 */
    {
        MP_ROM_QSTR(MP_QSTR_fat32_ls),
        MP_ROM_PTR(&psc_fat32_ls_obj)
    },

    /* Python script */
    {
        MP_ROM_QSTR(MP_QSTR_run),
        MP_ROM_PTR(&psc_run_obj)
    },

    /* TIMER */
    {
        MP_ROM_QSTR(MP_QSTR_timer_start),
        MP_ROM_PTR(&psc_timer_start_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_timer_start_auto),
        MP_ROM_PTR(&psc_timer_start_auto_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_timer_stop),
        MP_ROM_PTR(&psc_timer_stop_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_timer_count),
        MP_ROM_PTR(&psc_timer_count_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_timer_status),
        MP_ROM_PTR(&psc_timer_status_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_timer_running),
        MP_ROM_PTR(&psc_timer_running_obj)
    },


    {
        MP_ROM_QSTR(MP_QSTR_wait_us),
        MP_ROM_PTR(&psc_wait_us_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_wait_ms),
        MP_ROM_PTR(&psc_wait_ms_obj)
    },


    /* LED */
    {
        MP_ROM_QSTR(MP_QSTR_led_write),
        MP_ROM_PTR(&psc_led_write_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_on),
        MP_ROM_PTR(&psc_led_on_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_off),
        MP_ROM_PTR(&psc_led_off_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_toggle),
        MP_ROM_PTR(&psc_led_toggle_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_all_on),
        MP_ROM_PTR(&psc_led_all_on_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_all_off),
        MP_ROM_PTR(&psc_led_all_off_obj)
    },

    {
        MP_ROM_QSTR(MP_QSTR_led_state),
        MP_ROM_PTR(&psc_led_state_obj)
    },

};


/* ------------------------------------------------------------
 * module dictionary
 * ------------------------------------------------------------ */

static MP_DEFINE_CONST_DICT(
    psc_module_globals,
    psc_module_globals_table
);


/* ------------------------------------------------------------
 * module definition
 * ------------------------------------------------------------ */

const mp_obj_module_t psc_module = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&psc_module_globals,
};


/* ------------------------------------------------------------
 * import psc
 * ------------------------------------------------------------ */

MP_REGISTER_MODULE(MP_QSTR_psc, psc_module);