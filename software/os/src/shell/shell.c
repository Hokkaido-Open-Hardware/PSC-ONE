// shell.c
#include "../api/user.h"
#include "../fs/fat32.h"
#include "../kernel/elf_loader.h"
#include "../api/jpeg/jpeg_view.h"
#include "../api/tflite/tflite_api.h"
#include "../api/yolo/yolo.h"
#include "../api/robot/robot_control.h"
#include "../elego_robot/imu.h"
#include "../elego_robot/pwm_test.h"

// micropythonを含めるとSIM時間が長すぎる場合のオプション
#define PSC_OS_DEBUG_WITHOUT_MICROPYTHON 1

// JPEG LCD表示なしの場合のオプション
//#define PSC_OS_DEBUG_WITHOUT_JPEGLCD 1

extern int psc_micropython_run(void);

static void i2c_capture_hex(uint32_t byte)
{
    putchar("0123456789ABCDEF"[(byte >> 4) & 15u]);
    putchar("0123456789ABCDEF"[byte & 15u]);
}

static void cmd_i2c_capture(int self_only)
{
    uint32_t status = 0, polls = 0, before_abort = 0;
    int bytes = 0, elapsed_us = -1, cpu_timeout = 0, timed_watchdog = 0;
    /* Hardware normally finishes after 100M I2C peripheral clocks (1.25 s
     * at 80 MHz). CPU watchdog allows 10 s, independent of polling speed.
     * When the shared timer is busy, retain an explicitly uncalibrated guard. */
    const uint32_t fallback_polls = 10000000u;
    if (self_only && !(call_i2c_capture(I2C_CAPTURE_STATUS) & I2C_CAPTURE_SELF_SUPPORTED)) {
        printf("I2C self capture unsupported; rebuild/program FPGA.\n");
        return;
    }
    int timing = call_timer_measure_begin();
    uint32_t armed = call_i2c_capture(self_only ? I2C_CAPTURE_ARM_SELF : I2C_CAPTURE_ARM);
    if (armed == (uint32_t)-1) {
        if (timing == 0) call_timer_measure_end_us();
        printf("I2C capture ARM failed.\n");
        return;
    }
    if (self_only) printf("Capture filter: PSC-ONE slave address (slave remains active).\n");
    printf("I2C capture armed...\nWaiting for START...\n");
    for (;;) {
        status = call_i2c_capture(I2C_CAPTURE_STATUS);
        ++polls;
        if (status & I2C_CAPTURE_DONE) break;
        if (timing == 0) {
            elapsed_us = call_timer_measure_read_us();
            if (elapsed_us >= 10000000) { timed_watchdog = 1; break; }
            if (elapsed_us < 0 && polls >= fallback_polls) break;
        } else if (polls >= fallback_polls) break;
    }
    if (!(status & I2C_CAPTURE_DONE)) {
        /* Recheck before ABORT: RTL may have finished at the CPU deadline. */
        before_abort = call_i2c_capture(I2C_CAPTURE_STATUS);
        if (!(before_abort & I2C_CAPTURE_DONE)) {
            cpu_timeout = 1;
            call_i2c_capture(I2C_CAPTURE_ABORT);
        }
        status = call_i2c_capture(I2C_CAPTURE_STATUS);
    }
    if (timing == 0) elapsed_us = call_timer_measure_end_us();
    /* All diagnostics and event printing below occur after capture freezes. */
    printf("Capture status=%x, polls=%d, elapsed_us=%d\n",
           (unsigned)status, (unsigned)polls, elapsed_us);
    if (!(status & I2C_CAPTURE_MULTI))
        printf("RTL diagnostics unavailable: older FPGA image; single-STOP RTL may be installed. Rebuild/program FPGA.\n");
    else
        printf("RTL completed transactions (STOPs): %u\n",
               (unsigned)I2C_CAPTURE_STOPS(status));
    if (cpu_timeout)
        printf("CPU watchdog expired (%s); ABORT requested, status before ABORT=%x\n",
               timed_watchdog ? "10 seconds" : "10000000 polls; timer unavailable",
               (unsigned)before_abort);
    uint32_t count = call_i2c_capture(I2C_CAPTURE_COUNT);
    if (count > 64u) {
        printf("I2C capture: invalid event count\n");
        return;
    }
    for (uint32_t i = 0; i < count; ++i) {
        uint32_t event = call_i2c_capture(I2C_CAPTURE_POP);
        uint32_t kind = (event >> 9) & 7u;
        uint32_t byte = event & 255u;
        if (kind == 1u) printf("\nSTART\n");
        else if (kind == 2u) printf("\nREPEATED START\n");
        else if (kind == 3u) printf("STOP\n");
        else if (kind == 4u || kind == 5u) {
            printf(kind == 4u ? "ADDR : 0x" : "DATA : 0x");
            i2c_capture_hex(kind == 4u ? byte >> 1 : byte);
            if (kind == 4u) printf(byte & 1u ? " READ" : " WRITE");
            printf(event & 256u ? " NACK\n" : " ACK\n");
            ++bytes;
        }
    }
    printf("\nCaptured: %d bytes\n", bytes);
    if (status & I2C_CAPTURE_OVERFLOW)
        printf("RTL DONE: OVERFLOW (64-event buffer full); partial capture shown.\n");
    else if (status & I2C_CAPTURE_TIMEOUT)
        printf("RTL DONE: capture clock limit (includes idle timeout); partial capture shown.\n");
    else if (status & I2C_CAPTURE_ABORTED)
        printf("Capture aborted by CPU; partial capture shown.\n");
    else if (status & I2C_CAPTURE_LIMIT)
        printf("RTL DONE: transaction limit reached. Capture complete.\n");
    else
        printf("RTL DONE: unspecified reason (older RTL). Capture complete.\n");
}

void main(void) {

#if 0
    //SA API call
    //printf("call sa start.\n");
    call_sa_api(0x04);
    //printf("call sa returned.\n");

    // DUMP API call
    //call_dump_api();
#endif

    printf("shell start.\n");
    //cmd_primes(100);

    //exit();

    uint32_t prev_sw = 0;

    for (;;) {

prompt:
        //printf("main(void) start.\n");
        //printf("SP=%x\n", __builtin_frame_address(0));

        //printf("> ");
        putchar(0x1B); putchar('['); putchar('3'); putchar('4'); putchar('m'); // 青
        
        putchar('P');
        putchar('S');
        putchar('C');
        putchar('_');
        putchar('O');
        putchar('S');
        putchar('>');
        putchar(' ');
        
        putchar(0x1B); putchar('['); putchar('0'); putchar('m'); // リセット
        char cmdline[32];
        int len = 0;

        /* ===== 行入力（編集付き） =====
           - CR / LF を単体で改行とみなす（CRLFも自然に処理）
           - Backspace(0x08) / DEL(0x7F) で1文字削除
           - 制御文字は基本スキップ（tabは許容） */
        for (;;) {

#if 1
            /* ===== SW1, SW2 ポーリング ===== */
            uint32_t sw = poll_switch_api() & 0x03;

            bool sw1_pressed = ((prev_sw & 0x01) != 0) && ((sw & 0x01) == 0);
            bool sw2_pressed = ((prev_sw & 0x02) != 0) && ((sw & 0x02) == 0);

            if (sw1_pressed) {
                printf("SW1 pressed\n");
                //break;
            }

            if (sw2_pressed) {
                printf("SW2 pressed\n");
                //break;
            }

            prev_sw = sw;
#endif
#if 0
            int ch = getchar();
#else
            int ch = getchar_timeout();

            if (ch < 0) {
                continue;   // SWポーリングへ戻る
            }
#endif                        
            // CRLF 後の “余り LF” を無視（空バッファで LF が来たらスキップ）
            if (ch == '\n' && len == 0) {
                continue;
            }

            // バックスペース処理
            if (ch == 8 || ch == 127) {
                if (len > 0) {
                    len--;
                    // 端末上でも1文字消す
                    //printf("\b \b");
                    putchar('\b');
                    putchar(' ');
                    putchar('\b');
                }
                continue;
            }

            // 改行（CR / LF どちらも単体で終端）
            if (ch == '\r' || ch == '\n') {
                //printf("\n");
                putchar('\n');
                cmdline[len] = '\0';
                break;
            }

            // 制御文字は基本スキップ（\tは許容）
            if (ch < 0x20 && ch != '\t')
                continue;

            // 長さチェック（終端NULぶんを確保）
            if (len >= (int)sizeof(cmdline) - 1) {
                //printf("\ncommand line too long\n");
                goto prompt;
            }

            // 文字を追加 & エコー
            cmdline[len++] = (char)ch;
            putchar((char)ch);
        }

        // 空行なら次のプロンプトへ
        if (len == 0) continue;

        /* ===== トークン分割（空白区切り） ===== */
        #define ARGV_MAX 8
        const char *argv[ARGV_MAX];
        int argc = 0;

        // 先頭空白をスキップ
        char *p = cmdline;
        while (*p == ' ' || *p == '\t') p++;

        while (*p && argc < ARGV_MAX) {
            argv[argc++] = p;
            // 次の区切りまで進める
            while (*p && *p != ' ' && *p != '\t') p++;
            if (!*p) break;
            // 区切りをNULに
            *p++ = '\0';
            while (*p == ' ' || *p == '\t') p++;
        }

        if (argc == 0) continue;

        /* ===== コマンド分岐 ===== */
        if (strcmp(argv[0], "hello") == 0) {
            printf("Hello world from shell!\n");

        // ---- ELF run ----
        } else if (strcmp(argv[0], "run") == 0) {
            if (argc != 2) printf("usage: run FILE.ELF\n");
            else cmd_run_elf(argv[1]);

        // ---- Dump ----
        } else if (strcmp(argv[0], "dump") == 0) {

            uint32_t addr = 0x00200000;
            uint32_t len  = 0x100;
            uintptr_t val;

            if (argc >= 2) {
                if (parse_hex(argv[1], &val) == 0) {
                    addr = (uint32_t)val;
                }
            }

            if (argc >= 3) {
                if (parse_hex(argv[2], &val) == 0) {
                    len = (uint32_t)val;
                }
            }

            call_dump_api(addr, len);
        /*
        } else if (strcmp(argv[0], "hexdump") == 0) {
            // ユーザ空間から直接 hexdump を叩きたい場合のサンプル（任意）
            // ex) hexdump 0x100000 0x40
            unsigned addr = (argc >= 2) ? parse_u32(argv[1]) : USER_BASE;
            unsigned lenb = (argc >= 3) ? parse_u32(argv[2]) : 0x100;
            hexdump((const void*)addr, lenb, (uintptr_t)addr);
        */

        // ---- 素数出力サンプル ----
        } else if (strcmp(argv[0], "primes") == 0) {
            unsigned max = 1000;
            if (argc >= 2) {
                max = parse_u32(argv[1]);
                if (max > 100000) {
                    printf("max too large (<=100000)\n");
                    goto prompt;
                }
            }
            cmd_primes(max);

        // ---- セルフテスト ----
        } else if (strcmp(argv[0], "self_test") == 0) {
            //TBD
            //cmd_primes(max);

        // ---- PSC-NPU (SynapEngine) ----
        } else if (strcmp(argv[0], "sa_start") == 0) {
            uint32_t matrix_max = 4;
            if (argc >= 2) {
                matrix_max = parse_u32(argv[1]);
                if (matrix_max > 4) {
                    printf("matrix size > 4\n");
                    goto prompt;
                }
            }
            // SA API call 
            call_sa_api(matrix_max, true);

        // ---- ロボット制御 ----
        } else if (strcmp(argv[0], "robot_control") == 0) {
            call_robot_control();

        // ---- I2S MIC READ ----
        } else if (strcmp(argv[0], "mic_read") == 0) {
            if (argc < 2) {
                printf("usage: mic_read <count>\n");
                goto prompt;
            }

            unsigned count = parse_u32(argv[1]);
            call_mic_api(count);

        // ---- I2S MIC WRITE to FILE ----
        } else if (strcmp(argv[0], "mic_write") == 0) {
            if (argc < 2) {
                printf("usage: mic_write <count>\n");
                goto prompt;
            }

            unsigned count = parse_u32(argv[1]);
            //call_mic_write_api(count);
            call_mic_write_file(count);

        // ---- SDカードREAD ----
        } else if (strcmp(argv[0], "sd_read") == 0) {
            if (argc < 2) {
                printf("usage: sd_read <sector>\n");
                goto prompt;
            }

            unsigned sd_sector = parse_u32(argv[1]);
            call_sd_read_api(sd_sector);

        // ---- SDカードWRITE TEST----
        } else if (strcmp(argv[0], "sd_write") == 0) {
            if (argc < 2) {
                printf("usage: sd_write <sector>\n");
                goto prompt;
            }

            unsigned sd_sector = parse_u32(argv[1]);
            if (sd_sector < 5000) {
                printf("sd_sector write sector < 5000\n");
                goto prompt;
            }
            call_sd_write_test_api(sd_sector);

        // ---- FAT32 Info ----
        } else if (strcmp(argv[0], "fat32_info") == 0) {

            if (fat32_mount() != 0) {
                printf("FAT32 mount failed\n");
                goto prompt;
            }

            printf("part_lba=%x\n",      g_fat32.part_lba);
            printf("root_cluster=%x\n",  g_fat32.root_cluster);
            printf("spc=%x\n",           g_fat32.sectors_per_cluster);
            printf("fat_begin=%x\n",     g_fat32.fat_begin);
            printf("data_begin=%x\n",    g_fat32.data_begin);

        // ---- FAT32 ls ----
        } else if (strcmp(argv[0], "fat32_ls") == 0) {

            fat32_ls();

        // ---- FAT32 cat ----
        } else if (strcmp(argv[0], "fat32_cat") == 0) {

            if (argc < 2) {
                printf("usage: fat32_cat <file>\n");
                goto prompt;
            }

            fat32_cat(argv[1]);

        // ---- FAT32 read ----
        } else if (strcmp(argv[0], "fat32_read") == 0) {

            if (argc < 2) {
                printf("usage: fat32_read <file>\n");
                goto prompt;
            }

            uint8_t read_buf[512];
            uint32_t read_size = 0;

            if (fat32_read(argv[1], read_buf, sizeof(read_buf), &read_size) != 0) {
                printf("fat32_read failed\n");
                goto prompt;
            }

            printf("read size=%d\n", (int)read_size);

            for (uint32_t i = 0; i < read_size; i++) {
                putchar(read_buf[i]);
            }

            putchar('\n');

        // ---- FAT32 touch ----
        } else if (strcmp(argv[0], "fat32_touch") == 0) {

            if (argc < 2) {
                printf("usage: fat32_touch <file>\n");
                goto prompt;
            }

            if (fat32_touch(argv[1]) != 0) {
                printf("fat32_touch failed\n");
            } 

        } else if (strcmp(argv[0], "yolo_backend") == 0) {
            if (argc <= 2) cmd_yolo_backend(argc == 2 ? argv[1] : 0);
            else printf("usage: yolo_backend cpu|pulp|npu|auto\n");
        } else if (strcmp(argv[0], "yolo_diag") == 0) {
            if (argc == 2 && strcmp(argv[1], "on") == 0) cmd_yolo_diagnostics(1);
            else if (argc == 2 && strcmp(argv[1], "off") == 0) cmd_yolo_diagnostics(0);
            else printf("usage: yolo_diag on|off\n");
        } else if (strcmp(argv[0], "yolo") == 0) {
            if (argc == 3) cmd_yolo(argv[1], argv[2]);
            else printf("usage: yolo MODEL.TFL IMAGE.JPG\n");

        // ---- tf run ----
        } else if (strcmp(argv[0], "tflite_diag") == 0) {
            if(argc==2 && strcmp(argv[1],"on")==0) cmd_tflite_diagnostics(1);
            else if(argc==2 && strcmp(argv[1],"off")==0) cmd_tflite_diagnostics(0);
            else printf("usage: tflite_diag [on|off]\n");
        } else if (strcmp(argv[0], "tflite_run") == 0) {
            if (argc==2) cmd_tflite_run(argv[1]);
            else if(argc==3 && strcmp(argv[2],"cpu")==0) cmd_tflite_run_backend(argv[1],PSC_TFLITE_FC_CPU);
            else if(argc==3 && strcmp(argv[2],"npu")==0) cmd_tflite_run_backend(argv[1],PSC_TFLITE_FC_SYNAP);
            else if(argc==3 && strcmp(argv[2],"pulp")==0) cmd_tflite_run_backend(argv[1],PSC_TFLITE_FC_PULP);
            else if(argc==3 && strcmp(argv[2],"auto")==0) cmd_tflite_run_backend(argv[1],PSC_TFLITE_FC_AUTO);
            else printf("usage: tflite_run MODEL.TFL [cpu|npu|pulp|auto]\n");

        // ---- tf bench ----
        } else if (strcmp(argv[0], "tflite_bench") == 0) {
            if(argc==2)cmd_tflite_bench(argv[1]);
            else if(argc==3 && strcmp(argv[2],"quick")==0)cmd_tflite_bench_quick(argv[1]);
            else printf("usage: tflite_bench MODEL.TFL [quick]\n");

        // ---- tf info ----
        } else if (strcmp(argv[0], "tflite_info") == 0) {
            if (argc != 2) printf("usage: tflite_info MODEL.TFL\n");
            else cmd_tflite_info(argv[1]);

        // ---- JPEG disp LCD ----
#ifndef PSC_OS_DEBUG_WITHOUT_JPEGLCD
        } else if (strcmp(argv[0], "jpeg") == 0) {
            if (argc != 2) {
                printf("usage: jpeg TEST.JPG\n");
                goto prompt;
            }
            printf("JPEG start\n");
            int timing = call_timer_measure_begin();
            int jpeg_result = jpeg_view(argv[1]);
            int elapsed_ms = timing == 0 ? call_timer_measure_end() : -1;
            if (jpeg_result) printf("JPEG error: %s\n", jpeg_error_string(jpeg_result));
            else printf("decode OK\n");
            if (elapsed_ms >= 0) printf("time: %d ms\n", elapsed_ms);
            else printf("time: unavailable (timer busy)\n");
#endif

        // ---- 音声認識デモ ----
        } else if (strcmp(argv[0], "speech") == 0) {
            cmd_speech();
                    
        // ---- MicroPython REPL ----
#if !PSC_OS_DEBUG_WITHOUT_MICROPYTHON
        } else if (strcmp(argv[0], "microPython") == 0 ||
                   strcmp(argv[0], "micropython") == 0) {

            printf("\n--- MicroPython start ---\n");
            int mp_ret = psc_micropython_run();
            printf("\n--- return to PSC-OS shell (ret=%d) ---\n", mp_ret);
#endif
        // ---- PSC_Robot I2C ----
        } else if (strcmp(argv[0], "i2c_capture") == 0) {
            if (argc == 1) cmd_i2c_capture(0);
            else if (argc == 2 && strcmp(argv[1], "self") == 0) cmd_i2c_capture(1);
            else if (argc == 2 && strcmp(argv[1], "imu_read") == 0) cmd_i2c_imu(0);
            else if (argc == 2 && strcmp(argv[1], "imu_test") == 0) cmd_i2c_imu(1);
            else if (argc == 2 && strcmp(argv[1], "imu_monitor") == 0) cmd_i2c_imu(2);
            else if (argc == 2 && strcmp(argv[1], "pwm_test") == 0) cmd_i2c_pwm_test();
            else printf("usage: i2c_capture [self|imu_read|imu_test|imu_monitor|pwm_test]\n");

        // ---- Helps出力 ----
        } else if (strcmp(argv[0], "help") == 0) {
            printf("commands:\n");
            printf("  i2c_capture [self] (two transactions; bounded wait)\n");
            printf("  i2c_capture pwm_test (PWM transport round trip; no motor control)\n");
            printf("  i2c_capture imu_read (passive MPU6050 raw sample)\n");
            printf("  i2c_capture imu_test (math self-test + snapshot estimate)\n");
            printf("  i2c_capture imu_monitor (snapshots, reset per sample; q exits)\n");
            printf("  microPython | micropython\n");
            printf("  jpeg TEST.JPG\n");
            printf("  yolo YOLO.TFL TEST.JPG (detection to UART + LCD)\n");
            printf("  yolo_backend cpu|pulp|npu|auto (default cpu)\n");
            printf("  yolo_diag on|off (tensor hashes; default off)\n");
            printf("  run FILE.ELF\n");
            printf("  tflite_info MODEL.TFL (inspect only)\n");
            printf("  tflite_run MODEL.TFL [cpu|npu|pulp|auto]\n");
            printf("  tflite_diag [on|off] (includes operator trace during inference; default on)\n");
            printf("  tflite_bench MODEL.TFL [quick] (CPU/NPU/PULP/auto comparison)\n");
            printf("  hello\n");
            printf("  dump [addr] [len]\n");
            printf("  primes [max]\n");
            printf("  sa_start\n");
            printf("  sd_read\n");
            printf("  exit | quit | q (restart PSC-OS)\n");

        } else if (strcmp(argv[0], "exit") == 0 ||
                   strcmp(argv[0], "quit") == 0 ||
                   strcmp(argv[0], "q") == 0) {
            exit();
        
        } else {
            printf("unknown command: %s\n", argv[0]);
        }
    }
}

// -------------------------------------------------------
void cmd_primes(unsigned max)
{
    int count = 0;
    for (unsigned n = 2; n <= max; n++) {
        if (is_prime(n)) {
            printf("%d ", (int)n);
            count++;
            if ((count % 8) == 0)
                putchar('\n');
        }
    }
    if ((count % 8) != 0)
        putchar('\n');

    printf("total primes: %d (0..%d)\n", count, (int)max);
}

/* 簡易16進パーサ（"  0x1234" / "1234" 形式どちらも可） */
int parse_hex(const char *s, uintptr_t *out) {
    uintptr_t v = 0;

    /* skip leading spaces */
    while (*s == ' ' || *s == '\t') s++;

    /* optional 0x / 0X */
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
    if (!*s) return -1;

    while (*s) {
        char c = *s++;
        uint32_t d;
        if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
        else if (c >= 'a' && c <= 'f') d = 10u + (uint32_t)(c - 'a');
        else if (c >= 'A' && c <= 'F') d = 10u + (uint32_t)(c - 'A');
        else break;
        v = (v << 4) | d;
    }
    *out = v;
    return 0;
}
