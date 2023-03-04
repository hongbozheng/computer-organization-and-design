memtest.s:
.align 4
.section .text
.globl _start

_start:

      lb x1, byte
      lbu x1, byte
      lh x1, half
      lhu x1, half
      lw x1, word

      la x2, byte
      addi x1, x0, 127
      sb x1, 0(x2)
      lb x1, byte

      la x2, half
      addi x1, x0, 15
      sh x1, 0(x2)
      lh x1, half

      la x2, word
      addi x1, x0, 14
      sw x1, 0(x2)
      lw x1, word

      jal x4, _start

done:
      beq x0, x0, done

misalign:   .byte 0xFF
byte:       .byte 0x8A
half:       .half 0x800B
word:       .word 0x800000CD
