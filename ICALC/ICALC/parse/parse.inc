;
; File: parse/parse.inc
; Author: Christoffer Lundell (chrlu470)
;

.equ    NUM_OPERAND_DIGITS = WINDOW_WIDTH - 1
.equ    CHAR_BUF_SZ = WINDOW_WIDTH

.macro  STPTR
    movw    r5:r4, @0
.endmacro

.macro  LDPTR
    movw    @0, r5:r4
.endmacro

.macro  STADR
    ldi     r16, HIGH(@0)
    mov     r5, r16
    ldi     r16, LOW(@0)
    mov     r4, r16
.endmacro

.include    "parse/util.asm"
.include    "parse/sign.asm"
.include    "parse/operator.asm"
.include    "parse/parse.asm"
.include    "parse/boolean.asm"

VALID_OPERATORS: .db '+', '-', '*', '/', '%', '>', '<', '=', '\0', '\0'

; ******* DSEG *******
.dseg
CHAR_BUF:       .byte CHAR_BUF_SZ
EXPR_LAST:      .byte NUM_OPERAND_DIGITS
EXPR_LEFT:      .byte NUM_OPERAND_DIGITS
EXPR_RIGHT:     .byte NUM_OPERAND_DIGITS
EXPR_PARTIAL:   .byte NUM_OPERAND_DIGITS
EXPR_ONE:       .byte NUM_OPERAND_DIGITS
OPERATOR:       .byte 1
SIGN:           .byte 1

.cseg
; ******* CSEG *******
