;
; File: input_handling/input_handling.inc
; Author: Christoffer Lundell (chrlu470)
;

.include "input_handling/input_handling.asm"

.equ CHAR_BACKSPACE = 8
.equ CHAR_RETURN    = '\r'

; VALID_CHARS: All valid input characters except RETURN and BACKSPACE
VALID_CHARS: .db "0123456789/+-*%><=_ ", 0x0, 0x0

; ******* DSEG *******
.dseg

; ******* CSEG *******
.cseg
