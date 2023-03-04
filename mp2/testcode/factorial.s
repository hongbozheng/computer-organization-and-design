factorial.s:
 .align 4
 .section .text
 .globl factorial
 factorial:
         # Register a0 holds the input value
         # Register t0-t6 are caller-save, so you may use them without saving
         # Return value need to be put in register a0
         # Your code starts here
        lui t5, 1
        lui t4, 0
        ble a0, t5, one_ret # if a0 > 1 then target
        sub t0, a0, t5; # t0 = t1 - 1
loop_t0:
        beq t0, t5, ret; # if t0 == 1 then target
        sub t1, t0, t5 # t1 = t0 - 1
        addi t2, a0, 0; # t2 = a0 + 0
loop_t1:
        beq t1, t4, loop_mul; # if t1 == 0 then target
        # t1 != 0 keep adding
        add a0, a0, t2; # a0 = a0 + t2
        sub t1, t1, t5 # t1 = t1 - 1
        beq t0, t0, loop_t1;

loop_mul:
        sub t0, t0, t5 # t0 = t0 - 1
        beq t0, t0, loop_t0; 
                
        
        
 one_ret: 
        lui a0, 1
        beq t0, t0, ret;
 
 ret:
         jr ra # Register ra holds the return address
 .section .rodata
 # if you need any constants
 some_label:    .word 0x6
