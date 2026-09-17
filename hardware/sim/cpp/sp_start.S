.globl _start
_start:
    la   sp, _stack_top      # ← リンカシンボルを使う（固定値は使わない）
    # （RAMオンリーなら .data コピー不要、.bss ゼロは推奨）
    la   a0, __bss_start
    la   a1, __bss_end
1:  beq  a0, a1, 2f
    sw   x0, 0(a0)
    addi a0, a0, 4
    j    1b
2:
    tail run
