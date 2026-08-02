// shell.c
#include "user.h"
#include "fat32.h"

void main(void) {

    //SA API call
    //printf("call sa start.\n");
    call_sa_api(0x04);
    //printf("call sa returned.\n");

    // DUMP API call
    //call_dump_api();


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

        // ---- SynapEngine ----
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
            call_sa_api(matrix_max);

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

        // ---- FAT32 touch ----
        } else if (strcmp(argv[0], "fat32_touch") == 0) {

            if (argc < 2) {
                printf("usage: fat32_touch <file>\n");
                goto prompt;
            }

            if (fat32_touch(argv[1]) != 0) {
                printf("fat32_touch failed\n");
            } 
        } else if (strcmp(argv[0], "speech") == 0) {
            cmd_speech();
                    
        // ---- Helps出力 ----
        } else if (strcmp(argv[0], "help") == 0) {
            printf("commands:\n");
            /*
            printf("  hello\n");
            printf("  dump [addr] [len]\n");
            printf("  primes [max]\n");
            printf("  sa_start\n");
            printf("  sd_read\n");
            printf("  exit | quit | q\n");
            */

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