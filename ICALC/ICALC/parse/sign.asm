;
; File: parse/sign.asm
; Author: Christoffer Lundell (chrlu470)
;

; OP_MULT_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;                Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read/store)
; BCD-arithmetic multiplication of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Changes both BCD numbers to non-10s-complement before doing division
; uses the !(sign(LHS) ^ sign(RHS)) as the resulting sign
; Stores result at Z
OP_MULT_SIGNED:
    call    EXTRACT_SIGNS
    call    OP_MULT
    lds     r16, SIGN
    cpi     r16, '-'
    brne    OP_MULT_SIGNED_exit
    STADR   EXPR_LEFT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
OP_MULT_SIGNED_exit:
    ret

; OP_MOD_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;               Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read/store)
; BCD-arithmetic modulo of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores the integer division answer at EXPR_PARTIAL
; Stores the modulo result at Z
; Returns Z = false if the RHS operand is 0
OP_MOD_SIGNED:
    call    EXTRACT_SIGNS
    call    OP_MOD
    brne    OP_MOD_SIGNED_failure
    lds     r16, SIGN
    cpi     r16, '-'
    brne    OP_MOD_SIGNED_exit
    STADR   EXPR_LEFT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
    rjmp    OP_MOD_SIGNED_exit
OP_MOD_SIGNED_failure:
    clz
    rjmp    OP_MOD_SIGNED_ret
OP_MOD_SIGNED_exit:
    sez
OP_MOD_SIGNED_ret:
    ret

; OP_DIV_SIGNED(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;               Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read/store)
; BCD-arithmetic division of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Changes both BCD numbers to non-10s-complement before doing division
; uses the !(sign(LHS) ^ sign(RHS)) as the resulting sign
; Stores the integer division result at Z
; Returns Z = false if the RHS operand is 0
OP_DIV_SIGNED:
    call    EXTRACT_SIGNS
    call    OP_DIV
    brne    OP_DIV_SIGNED_failure
    lds     r16, SIGN
    cpi     r16, '-'
    brne    OP_DIV_SIGNED_exit
    STADR   EXPR_LEFT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
    rjmp    OP_DIV_SIGNED_ret
OP_DIV_SIGNED_failure:
    clz
    rjmp    OP_DIV_SIGNED_ret
OP_DIV_SIGNED_exit:
    sez
OP_DIV_SIGNED_ret:
    ret

; TENS_COMPLEMENT(r5:r4: end of Array<BCD, NUM_OPERAND_DIGITS> = read/write)
; Replaces [r5:r4] with its tens complement
TENS_COMPLEMENT:
    push    ZH
    push    ZL
    push    YH
    push    YL

    LDPTR   Y
    call    NINES_COMPLEMENT
    LDPTR   Z
    ldi     YH, HIGH(EXPR_ONE + NUM_OPERAND_DIGITS)
    ldi     YL, LOW(EXPR_ONE + NUM_OPERAND_DIGITS)
    call    OP_PLUS

    pop     YL
    pop     YH
    pop     ZL
    pop     ZH
    ret

; NINES_COMPLEMENT(Y: end of Array<BCD, NUM_OPERAND_DIGITS> = read/write)
; Replaces [Y] with its nines complement
; Changes Y to Y - NUM_OPERAND_DIGITS
NINES_COMPLEMENT:
    ldi     r17, 0x0F ; bitmask for inverting BCD
    ldi     r18, NUM_OPERAND_DIGITS ; Loop counter
NINES_COMPLEMENT_loop:
    ld      r16, -Y
    eor     r16, r17
    subi    r16, 6
    st      Y, r16
    dec     r18
    brne    NINES_COMPLEMENT_loop
    ret

; EXTRACT_SIGNS(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/write,
;               Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read/write
; Adjusts both the LHS and RHS array to be positive
; Saves the resulting sign in memory at SIGN according to !(sign(LHS) ^ sign(RHS)
EXTRACT_SIGNS:
    ldi     r16, '+'
    sts     SIGN, r16
    lds     r16, EXPR_LEFT
    cpi     r16, 5
    brlo    EXTRACT_SIGNS_check_right
    ldi     r16, '-'
    sts     SIGN, r16
    STADR   EXPR_LEFT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
EXTRACT_SIGNS_check_right:
    lds     r16, EXPR_RIGHT
    cpi     r16, 5
    brlo    EXTRACT_SIGNS_exit
    call    INVERT_SIGN
    STADR   EXPR_RIGHT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
EXTRACT_SIGNS_exit:
    ret

; INVERT_SIGN
; switches from '+' to '-' and vice versa
INVERT_SIGN:
    lds     r17, SIGN
    cpi     r17, '+'
    brne    INVERT_SIGN_minus
    ldi     r17, '-'
    sts     SIGN, r17
    rjmp    INVERT_SIGN_exit
INVERT_SIGN_minus:
    ldi     r17, '+'
    sts     SIGN, r17
INVERT_SIGN_exit:
    ret
