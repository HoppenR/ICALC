;
; File: main.asm
; Author: Christoffer Lundell (chrlu470)
;

jmp INIT

.include "output_handling/output_handling.inc"
.include "input_handling/input_handling.inc"
.include "parse/parse.inc"
.include "uart/uart.asm"

INIT:
    ldi     r16, HIGH(RAMEND)
    out     SPH, r16
    ldi     r16, LOW(RAMEND)
    out     SPL, r16
    call    HW_INIT
    call    PRINT_STARTSCREEN

MAIN:
    call    INPUT_HANDLER
    call    PARSE_EXPR
    call    PRINT_RESULT
    rjmp    MAIN

HW_INIT:
    ; NOTE: Using r2 as a zero-register
    clr     r2
    call    UART_INIT
    call    OUTPUT_HANDLER_INIT
    call    PARSE_INIT
    ret
