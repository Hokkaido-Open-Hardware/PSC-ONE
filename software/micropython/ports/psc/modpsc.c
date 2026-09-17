#include "py/obj.h"
#include "py/objlist.h"
#include "py/runtime.h"
#include "py/compile.h"
#include "py/repl.h"
#include "py/mperrno.h"

#include "mphalport.h"
#include <string.h>
#include "../../../os/src/tflite/tflite_api.h"


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
    // Read one extra byte so an oversized file cannot look complete.
    static uint8_t buf[PSC_PY_MAX_SIZE + 1u];
    uint32_t size = 0;

    if (fat32_read(
            filename,
            buf,
            sizeof(buf),
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
 * SynapEngine
 * ------------------------------------------------------------ */

#ifndef PSC_SA_MAT_MAX
#define PSC_SA_MAT_MAX 16u
#endif

extern int psc_sa_run_api(
    const uint8_t *A,
    const uint8_t *B,
    uint32_t *C,
    uint32_t n,
    bool signed_mode
);

/* Python: psc.sa_run(A, B, signed_mode) */
static mp_obj_t psc_sa_run(
    mp_obj_t A_obj,
    mp_obj_t B_obj,
    mp_obj_t signed_mode_obj)
{
    size_t n = 0;
    size_t bn = 0;
    mp_obj_t *A_rows = NULL;
    mp_obj_t *B_rows = NULL;

    mp_obj_get_array(A_obj, &n, &A_rows);
    mp_obj_get_array(B_obj, &bn, &B_rows);

    bool signed_mode = mp_obj_is_true(signed_mode_obj);

    if ((n == 0u) ||
        (n > PSC_SA_MAT_MAX) ||
        ((n & 3u) != 0u)) {

        mp_raise_ValueError(
            MP_ERROR_TEXT("invalid matrix size")
        );
    }

    if (bn != n) {
        mp_raise_ValueError(
            MP_ERROR_TEXT("matrix size mismatch")
        );
    }

    static uint8_t A_buf[PSC_SA_MAT_MAX * PSC_SA_MAT_MAX];
    static uint8_t B_buf[PSC_SA_MAT_MAX * PSC_SA_MAT_MAX];
    static uint32_t C_buf[PSC_SA_MAT_MAX * PSC_SA_MAT_MAX];

    /*
     * Matrix A
     */
    for (size_t i = 0; i < n; ++i) {
        size_t cols = 0;
        mp_obj_t *row = NULL;

        mp_obj_get_array(A_rows[i], &cols, &row);

        if (cols != n) {
            mp_raise_ValueError(
                MP_ERROR_TEXT("A must be square")
            );
        }

        for (size_t j = 0; j < n; ++j) {
            mp_int_t value = mp_obj_get_int(row[j]);

            if (signed_mode) {

                /*
                 * Signed INT8:
                 * -128 ... +127
                 */
                if ((value < -128) || (value > 127)) {
                    mp_raise_ValueError(
                        MP_ERROR_TEXT(
                            "A signed value out of range"
                        )
                    );
                }

            } else {

                /*
                 * Unsigned UINT8:
                 * 0 ... 255
                 */
                if ((value < 0) || (value > 255)) {
                    mp_raise_ValueError(
                        MP_ERROR_TEXT(
                            "A unsigned value out of range"
                        )
                    );
                }
            }

            /*
             * Signed values are stored as two's-complement
             * 8-bit values in the uint8_t buffer.
             *
             * Example:
             *   -1   -> 0xFF
             *   -128 -> 0x80
             *   127  -> 0x7F
             */
            A_buf[i * n + j] = (uint8_t)value;
        }
    }

    /*
     * Matrix B
     */
    for (size_t i = 0; i < n; ++i) {
        size_t cols = 0;
        mp_obj_t *row = NULL;

        mp_obj_get_array(B_rows[i], &cols, &row);

        if (cols != n) {
            mp_raise_ValueError(
                MP_ERROR_TEXT("B must be square")
            );
        }

        for (size_t j = 0; j < n; ++j) {
            mp_int_t value = mp_obj_get_int(row[j]);

            if (signed_mode) {

                /*
                 * Signed INT8:
                 * -128 ... +127
                 */
                if ((value < -128) || (value > 127)) {
                    mp_raise_ValueError(
                        MP_ERROR_TEXT(
                            "B signed value out of range"
                        )
                    );
                }

            } else {

                /*
                 * Unsigned UINT8:
                 * 0 ... 255
                 */
                if ((value < 0) || (value > 255)) {
                    mp_raise_ValueError(
                        MP_ERROR_TEXT(
                            "B unsigned value out of range"
                        )
                    );
                }
            }

            B_buf[i * n + j] = (uint8_t)value;
        }
    }

    /*
     * Run SynapEngine
     */
    int ret = psc_sa_run_api(
        A_buf,
        B_buf,
        C_buf,
        (uint32_t)n,
        signed_mode
    );

    if (ret != 0) {
        mp_raise_OSError(ret);
    }

    /*
     * Convert result matrix to MicroPython list
     */
    mp_obj_t result = mp_obj_new_list(n, NULL);
    mp_obj_list_t *result_list = MP_OBJ_TO_PTR(result);

    for (size_t i = 0; i < n; ++i) {
        mp_obj_t row_obj = mp_obj_new_list(n, NULL);
        mp_obj_list_t *row_list = MP_OBJ_TO_PTR(row_obj);

        for (size_t j = 0; j < n; ++j) {

            if (signed_mode) {
                row_list->items[j] = mp_obj_new_int(
                    (int32_t)C_buf[i * n + j]
                );
            } else {
                row_list->items[j] = mp_obj_new_int_from_uint(
                    C_buf[i * n + j]
                );
            }
        }

        result_list->items[i] = row_obj;
    }

    return result;
}

static MP_DEFINE_CONST_FUN_OBJ_3(
    psc_sa_run_obj,
    psc_sa_run
);


/* ------------------------------------------------------------
 * TFLite: ユーザー側の既存C APIをPythonへ公開する。
 * シェルと単一モデルを共有し、新しいsyscallは使用しない。
 * ------------------------------------------------------------ */

/* TFLite lives in the same user image as MicroPython. Only copy Python
 * buffers; never retain a GC-owned pointer or expose the runtime arena. */
/* C APIの失敗をOSErrorへ変換する。元の負のエラー番号を保持する。 */
static void mod_psc_tflite_check(int rc)
{
    if (rc != 0) {
        mp_raise_OSError(rc);
    }
}

/* Python: psc.tflite_load("MODEL.TFL") -> None
 * SDルートの大文字8.3形式のファイルを読み、推論を準備する。
 * モデルはC側の静的バッファに保持される。C APIでのload失敗時も
 * 旧モデルは無効になる。Python文字列の埋め込みNULは事前に拒否する。 */
static mp_obj_t mod_psc_tflite_load(mp_obj_t name_obj)
{
    if (!mp_obj_is_str(name_obj)) {
        mp_raise_TypeError(MP_ERROR_TEXT("filename must be str"));
    }
    size_t length;
    const char *name = mp_obj_str_get_data(name_obj, &length);
    if (memchr(name, '\0', length) != NULL) {
        mp_raise_ValueError(MP_ERROR_TEXT("filename contains NUL"));
    }
    mod_psc_tflite_check(psc_tflite_load(name));
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(mod_psc_tflite_load_obj, mod_psc_tflite_load);

/* Python: psc.tflite_reset() -> None
 * モデル・入出力・計測状態を初期化し、CPU backend / tile=4へ戻す。
 * 過去にPythonへ返したbytesはコピーなので、この操作の影響を受けない。 */
static mp_obj_t mod_psc_tflite_reset(void)
{
    mod_psc_tflite_check(psc_tflite_reset());
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_0(mod_psc_tflite_reset_obj, mod_psc_tflite_reset);

/* Python: psc.tflite_input_size() -> int
 * 準備済みモデルが要求する入力バイト数。未ロード時はOSError。 */
static mp_obj_t mod_psc_tflite_input_size(void)
{
    size_t length;
    if (psc_tflite_get_input(&length) == NULL) {
        mp_raise_OSError(PSC_TFLITE_ERR_GRAPH);
    }
    return mp_obj_new_int_from_uint(length);
}
static MP_DEFINE_CONST_FUN_OBJ_0(mod_psc_tflite_input_size_obj, mod_psc_tflite_input_size);

/* Python: psc.tflite_run(data) -> bytes
 * 読み取り可能バッファをINT8の生バイト列（負値は2の補数）として扱う。
 * 長さの完全一致を確認後、入力コピー→同期推論→出力コピーを行う。
 * strはTypeError、長さ不一致はValueError、推論失敗はOSError。
 * 返すbytesはPython所有で、内部バッファへの参照を公開しない。 */
static mp_obj_t mod_psc_tflite_run(mp_obj_t data_obj)
{
    if (mp_obj_is_str(data_obj)) {
        mp_raise_TypeError(MP_ERROR_TEXT("input must be a byte buffer"));
    }
    mp_buffer_info_t data;
    mp_get_buffer_raise(data_obj, &data, MP_BUFFER_READ);
    size_t length;
    int8_t *input = psc_tflite_get_input(&length);
    if (input == NULL) {
        mp_raise_OSError(PSC_TFLITE_ERR_GRAPH);
    }
    if (data.len != length) {
        mp_raise_ValueError(MP_ERROR_TEXT("TFLite input size mismatch"));
    }
    /* No Python allocation or callback between input copy and invoke. */
    memcpy(input, data.buf, length);
    mod_psc_tflite_check(psc_tflite_invoke());
    const int8_t *output = psc_tflite_get_output(&length);
    if (output == NULL) {
        mp_raise_OSError(PSC_TFLITE_ERR_GRAPH);
    }
    return mp_obj_new_bytes((const byte *)output, length);
}
static MP_DEFINE_CONST_FUN_OBJ_1(mod_psc_tflite_run_obj, mod_psc_tflite_run);

/* Python: psc.tflite_set_fc_backend(backend) -> None
 * 0=CPU、1=Synap。その他はValueError。モデルと入力は保持されるが、
 * 内部の推論結果は無効になる。Synap失敗時のCPU自動切替は行わない。 */
static mp_obj_t mod_psc_tflite_set_fc_backend(mp_obj_t backend_obj)
{
    mp_int_t backend = mp_obj_get_int(backend_obj);
    if (backend != PSC_TFLITE_FC_CPU && backend != PSC_TFLITE_FC_SYNAP) {
        mp_raise_ValueError(MP_ERROR_TEXT("backend must be 0 (CPU) or 1 (Synap)"));
    }
    mod_psc_tflite_check(psc_tflite_set_fc_backend((enum psc_tflite_fc_backend)backend));
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(mod_psc_tflite_set_fc_backend_obj, mod_psc_tflite_set_fc_backend);

/* Python: psc.tflite_set_synap_tile_size(size) -> None
 * Synap行列演算のタイル寸法を4/8/12/16から選ぶ。その他はValueError。
 * backend自体は変更せず、内部の推論結果を無効にする。 */
static mp_obj_t mod_psc_tflite_set_synap_tile_size(mp_obj_t size_obj)
{
    mp_int_t size = mp_obj_get_int(size_obj);
    if (size != 4 && size != 8 && size != 12 && size != 16) {
        mp_raise_ValueError(MP_ERROR_TEXT("tile size must be 4, 8, 12 or 16"));
    }
    mod_psc_tflite_check(psc_tflite_set_synap_tile_size((unsigned)size));
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(mod_psc_tflite_set_synap_tile_size_obj, mod_psc_tflite_set_synap_tile_size);

/* Python: psc.tflite_arena_used() -> int
 * C側arenaの使用バイト数（reset後は0）。Pythonヒープ使用量ではない。 */
static mp_obj_t mod_psc_tflite_arena_used(void)
{
    return mp_obj_new_int_from_uint(psc_tflite_arena_used());
}
static MP_DEFINE_CONST_FUN_OBJ_0(mod_psc_tflite_arena_used_obj, mod_psc_tflite_arena_used);

/* Pythonのpscモジュールに公開する関数名と関数オブジェクトの対応表。 */
static const mp_rom_map_elem_t psc_module_globals_table[] = {

    { MP_ROM_QSTR(MP_QSTR_tflite_load), MP_ROM_PTR(&mod_psc_tflite_load_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_reset), MP_ROM_PTR(&mod_psc_tflite_reset_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_input_size), MP_ROM_PTR(&mod_psc_tflite_input_size_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_run), MP_ROM_PTR(&mod_psc_tflite_run_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_set_fc_backend), MP_ROM_PTR(&mod_psc_tflite_set_fc_backend_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_set_synap_tile_size), MP_ROM_PTR(&mod_psc_tflite_set_synap_tile_size_obj) },
    { MP_ROM_QSTR(MP_QSTR_tflite_arena_used), MP_ROM_PTR(&mod_psc_tflite_arena_used_obj) },

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

    /* SynapEngine */
    {
        MP_ROM_QSTR(MP_QSTR_sa_run),
        MP_ROM_PTR(&psc_sa_run_obj)
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
