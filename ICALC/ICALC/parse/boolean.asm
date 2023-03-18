;
; File: parse/boolean.asm
; Author: Christoffer Lundell (chrlu470)
;

; GREATER_EQUAL(Z: beginning of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read
;               Y: beginning of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; returns flag Z = true if the BCD array at Z is greater or equal to the one at Y
; Z is set to Z + NUM_OPERAND_DIGITS
; Y is set to Y + NUM_OPERAND_DIGITS
GREATER_EQUAL:
    ldi     r16, NUM_OPERAND_DIGITS
GREATER_EQUAL_loop:
    ld      r17, Z+ ; LHS
    ld      r18, Y+ ; RHS
    dec     r16
    cp      r18, r17
    brlo    GREATER_EQUAL_true
    brne    GREATER_EQUAL_false
    cpi     r16, 0
    brne    GREATER_EQUAL_loop
GREATER_EQUAL_true:
    sez
    rjmp    GREATER_EQUAL_exit
GREATER_EQUAL_false:
    clz
GREATER_EQUAL_exit:
    in      r17, SREG
    add     ZL, r16
    adc     ZH, r2
    add     YL, r16
    adc     YH, r2
    out     SREG, r17
    ret

; EQUAL_TO(Z: beginning of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read
;          Y: beginning of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; returns flag Z = true if the BCD array at Z is equal to the one at Y
; Z is set to Z + NUM_OPERAND_DIGITS
; Y is set to Y + NUM_OPERAND_DIGITS
EQUAL_TO:
    ldi     r16, NUM_OPERAND_DIGITS
EQUAL_TO_loop:
    ld      r17, Z+ ; LHS
    ld      r18, Y+ ; RHS
    dec     r16
    cp      r18, r17
    brne    EQUAL_TO_false
    cpi     r16, 0
    brne    EQUAL_TO_loop
EQUAL_TO_true:
    sez
    rjmp    EQUAL_TO_exit
EQUAL_TO_false:
    clz
EQUAL_TO_exit:
    in      r17, SREG
    add     ZL, r16
    adc     ZH, r2
    add     YL, r16
    adc     YH, r2
    out     SREG, r17
    ret

; COMPARE_SIGNED(Z: beginning of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read
;                Y: beginning of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; returns r16 = 255 if less, 0 if equal, 1 if positive
; Changes Z
; Changes Y
COMPARE_SIGNED:
    call    EQUAL_TO
    breq    COMPARE_SIGNED_equal
    sbiw    Y, NUM_OPERAND_DIGITS
    sbiw    Z, NUM_OPERAND_DIGITS
    ld      r16, Z
    cpi     r16, 5
    brlo    COMPARE_SIGNED_left_plus
    ld      r16, Y
    cpi     r16, 5
    brlo    COMPARE_SIGNED_less
    call    GREATER_EQUAL
    breq    COMPARE_SIGNED_greater
    rjmp    COMPARE_SIGNED_less
COMPARE_SIGNED_left_plus:
    ld      r16, Y
    cpi     r16, 5
    brsh    COMPARE_SIGNED_greater
    call    GREATER_EQUAL
    breq    COMPARE_SIGNED_greater
COMPARE_SIGNED_less:
    ldi     r16, 255
    rjmp    COMPARE_SIGNED_ret
COMPARE_SIGNED_equal:
    ldi     r16, 0
    rjmp    COMPARE_SIGNED_ret
COMPARE_SIGNED_greater:
    ldi     r16, 1
COMPARE_SIGNED_ret:
    ret

; GREATER_THAN_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/write
;                     Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; Changes Y
; Changes Z
; Sets LHS to 1 if LHS > RHS
GREATER_THAN_SIGNED:
    sbiw    Z, NUM_OPERAND_DIGITS
    sbiw    Y, NUM_OPERAND_DIGITS
    STPTR   Z
    call    COMPARE_SIGNED
    cpi     r16, 1
    call    STORE_IF
    ret

; LESS_THAN_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/write
;                  Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; Changes Y
; Changes Z
; Sets LHS to 1 if LHS < RHS
LESS_THAN_SIGNED:
    sbiw    Z, NUM_OPERAND_DIGITS
    sbiw    Y, NUM_OPERAND_DIGITS
    STPTR   Z
    call    COMPARE_SIGNED
    cpi     r16, 255
    call    STORE_IF
    ret

; EQUAL_TO_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/write
;                 Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; Changes Y
; Changes Z
; Sets LHS to 1 if LHS == RHS
EQUAL_TO_SIGNED:
    sbiw    Z, NUM_OPERAND_DIGITS
    sbiw    Y, NUM_OPERAND_DIGITS
    STPTR   Z
    call    COMPARE_SIGNED
    cpi     r16, 0
    call    STORE_IF
    ret
