;
; File: parse/operator.asm
; Author: Christoffer Lundell (chrlu470)
;

; PERFORM_OP
; Reads OPERATOR and applies corresponding operation on EXPR_LEFT and EXPR_RIGHT
; Changes EXPR_LEFT and EXPR_RIGHT
PERFORM_OP:
    ldi     ZH, HIGH(EXPR_LEFT + NUM_OPERAND_DIGITS)
    ldi     ZL, LOW(EXPR_LEFT + NUM_OPERAND_DIGITS)
    ldi     YH, HIGH(EXPR_RIGHT + NUM_OPERAND_DIGITS)
    ldi     YL, LOW(EXPR_RIGHT + NUM_OPERAND_DIGITS)
    lds     r16, OPERATOR
    cpi     r16, '+'
    brne    PERFORM_OP_check_minus
    call    OP_PLUS
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_minus:
    cpi     r16, '-'
    brne    PERFORM_OP_check_mult
    call    OP_MINUS
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_mult:
    cpi     r16, '*'
    brne    PERFORM_OP_check_div
    call    OP_MULT_SIGNED
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_div:
    cpi     r16, '/'
    brne    PERFORM_OP_check_mod
    call    OP_DIV_SIGNED
    brne    PERFORM_OP_failure
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_mod:
    cpi     r16, '%'
    brne    PERFORM_OP_check_greater_than
    call    OP_MOD_SIGNED
    brne    PERFORM_OP_failure
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_greater_than:
    cpi     r16, '>'
    brne    PERFORM_OP_check_less_than
    call    GREATER_THAN_SIGNED
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_less_than:
    cpi     r16, '<'
    brne    PERFORM_OP_check_equal_to
    call    LESS_THAN_SIGNED
    rjmp    PERFORM_OP_exit
PERFORM_OP_check_equal_to:
    cpi     r16, '='
    brne    PERFORM_OP_failure
    call    EQUAL_TO_SIGNED
    rjmp    PERFORM_OP_exit
PERFORM_OP_failure:
    clz
    rjmp    PERFORM_OP_ret
PERFORM_OP_exit:
    sez
PERFORM_OP_ret:
    ret

; OP_PLUS(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;         Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; BCD-arithmetic addition of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores result at Z
; Changes Z to Z - NUM_OPERAND_DIGITS
; Changes Y to Y - NUM_OPERAND_DIGITS
OP_PLUS:
    clr     r17 ; carry
    ldi     r18, NUM_OPERAND_DIGITS
OP_PLUS_loop:
    ld      r16, -Z ; LHS
    add     r16, r17 ; Adding carry bit
    ld      r17, -Y ; RHS
    add     r16, r17 ; Adding right side
    cpi     r16, 10
    ; if result >= 10, add 6
    brlo    OP_PLUS_no_add6
    ldi     r17, 6
    add     r16, r17
OP_PLUS_no_add6:
    ; move the higher nibble of r16 to the lower nibble of r17 (carry)
    mov     r17, r16
    andi    r16, 0x0F
    swap    r17
    andi    r17, 0x0F
    st Z,   r16
    dec     r18
    brne    OP_PLUS_loop
    ret

; OP_MINUS(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;          Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; BCD-arithmetic subtraction of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores result at Z
OP_MINUS:
    STPTR   Y
    call    TENS_COMPLEMENT
    call    OP_PLUS
    adiw    Z, NUM_OPERAND_DIGITS
    adiw    Y, NUM_OPERAND_DIGITS
    ; Switch RHS back to non-10s-complement (only needed for OP_DIV)
    call    TENS_COMPLEMENT
    ret

; OP_MULT(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;         Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; BCD-arithmetic multiplication of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores result at Z
; Changes Z
; Changes Y
OP_MULT:
    ; Prepare arguments for COPY_EXPR
    ldi     XH, HIGH(EXPR_PARTIAL)
    ldi     XL, LOW(EXPR_PARTIAL)
    sbiw    Z, NUM_OPERAND_DIGITS
    ; Store Z as argument to SHIFT_EXPR_TO_LEFT
    STPTR   Z
    call    COPY_EXPR
    sbiw    X, NUM_OPERAND_DIGITS
    ldi     r19, NUM_OPERAND_DIGITS
OP_MULT_loop:
    call    SHIFT_EXPR_TO_LEFT
    ld      r20, X+
    cpi     r20, 0
    breq    OP_MULT_exit_add_loop
OP_MULT_add_loop:
    call    OP_PLUS
    adiw    Y, NUM_OPERAND_DIGITS
    adiw    Z, NUM_OPERAND_DIGITS
    dec     r20
    brne    OP_MULT_add_loop
OP_MULT_exit_add_loop:
    dec     r19
    brne    OP_MULT_loop
    ret

; OP_MOD(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;        Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; BCD-arithmetic modulo of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores the integer division answer at EXPR_PARTIAL
; Stores the modulo result at Z
; Returns Z = false if the RHS operand is 0
OP_MOD:
    ; Check if RHS is 0
    STPTR   Y
    call    IS_EMPTY
    breq    OP_MOD_failure
    STADR   EXPR_PARTIAL
    call    CLEAR_ARRAY
    ; Stores max shifts in r18
    STPTR   Y
    call    MAX_SHIFTS
    ; Store shift amount
    inc     r18
    mov     r19, r18
    sbiw    Y, NUM_OPERAND_DIGITS
    STPTR   Y
    adiw    Y, NUM_OPERAND_DIGITS
    rjmp    OP_MOD_preshift_while_shifts
OP_MOD_preshift_loop:
    ; Argument for SHIFT_EXPR_TO_LEFT
    call    SHIFT_EXPR_TO_LEFT
OP_MOD_preshift_while_shifts:
    dec     r18
    brne    OP_MOD_preshift_loop
    rjmp    OP_MOD_while_ge
OP_MOD_subtract_loop:
    call    OP_MINUS
    lds     r16, (EXPR_PARTIAL + NUM_OPERAND_DIGITS - 1)
    inc     r16
    sts     (EXPR_PARTIAL + NUM_OPERAND_DIGITS - 1), r16
OP_MOD_while_ge:
    ; branch to div subtract loop while LHS >= RHS
    sbiw    Y, NUM_OPERAND_DIGITS
    sbiw    Z, NUM_OPERAND_DIGITS
    call    GREATER_EQUAL
    breq    OP_MOD_subtract_loop
    ; Done?
    dec     r19
    breq    OP_MOD_exit
    ; Shift RHS right
    STPTR   Y
    call    SHIFT_EXPR_TO_RIGHT
    STADR   EXPR_PARTIAL
    call    SHIFT_EXPR_TO_LEFT
    rjmp    OP_MOD_while_ge
OP_MOD_failure:
    clz
    rjmp    OP_MOD_ret
OP_MOD_exit:
    sez
OP_MOD_ret:
    ret

; OP_DIV(Z: end of Array<BCD, NUM_OPERAND_DIGITS> = LHS, read/store
;        Y: end of Array<BCD, NUM_OPERAND_DIGITS> = RHS, read)
; BCD-arithmetic division of two BCD-encoded numbers with
; NUM_OPERAND_DIGITS each
; Stores the integer division result at Z
; Returns Z = false if the RHS operand is 0
OP_DIV:
    call    OP_MOD
    brne    OP_DIV_ret
    ; Copy over the integer division answer from EXPR_PARTIAL
    ldi     ZH, HIGH(EXPR_PARTIAL)
    ldi     ZL, LOW(EXPR_PARTIAL)
    ldi     XH, HIGH(EXPR_LEFT)
    ldi     XL, LOW(EXPR_LEFT)
    call    COPY_EXPR
OP_DIV_ret:
    ret
