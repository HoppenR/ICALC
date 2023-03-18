;
; File: output_handling/output_handling.inc
; Author: Christoffer Lundell (chrlu470)
;

.equ    WINDOW_WIDTH  = 40
.equ    WINDOW_HEIGHT = 30

; Special characters
.equ    CHAR_SCROLLDOWN = 11
.equ    CHAR_CLEAR      = 12

.include "output_handling/output_handling.asm"
.include "output_handling/startscreen.asm"

; ******* DSEG *******
.dseg
LINE: .byte 1

; ******* CSEG *******
.cseg
