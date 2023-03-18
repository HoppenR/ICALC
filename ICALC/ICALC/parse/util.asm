;
; File: parse/util.asm
; Author: Christoffer Lundell (chrlu470)
;

; SHIFT_EXPR_TO_LEFT(r5:r4: beginning of Array<BCD, NUM_OPERAND_DIGITS> = read/write)
; Shifts array starting at Y one step to the left, as if "multiplying" by 10
; Changes the next NUM_OPERAND_DIGITS starting at r5:r4
; The rightmost digit is set to 0
SHIFT_EXPR_TO_LEFT:
    push    YH
    push    YL

    LDPTR   Y
    ldi     r16, NUM_OPERAND_DIGITS - 1
SHIFT_EXPR_TO_LEFT_loop:
    ldd     r17, Y+1
    st      Y+, r17
    dec     r16
    brne    SHIFT_EXPR_TO_LEFT_loop
    clr     r17
    st      Y+, r17

    pop     YL
    pop     YH
    ret

; SHIFT_EXPR_TO_RIGHT(r5:r4: end of Array<BCD, NUM_OPERAND_DIGITS> = read/write)
; Shifts array starting at Y one step to the right, as if "dividing" by 10
; Changes the next NUM_OPERAND_DIGITS starting at r5:r4
; The leftmost digit is set to 0
SHIFT_EXPR_TO_RIGHT:
    push    YH
    push    YL

    LDPTR   Y
    ldi     r16, NUM_OPERAND_DIGITS
SHIFT_EXPR_TO_RIGHT_loop:
    ld      r17, -Y
    std     Y+1, r17
    dec     r16
    brne    SHIFT_EXPR_TO_RIGHT_loop
    clr     r17
    st      Y, r17

    pop     YL
    pop     YH
    ret

; COPY_EXPR(X: beginning of Array<BCD, NUM_OPERAND_DIGITS> = write,
;           Z: beginning of Array<BCD, NUM_OPERAND_DIGITS> = read)
; Changes X pointer to X + NUM_OPERAND_DIGITS
; Changes Z pointer to Z + NUM_OPERAND_DIGITS
COPY_EXPR:
    ldi     r16, NUM_OPERAND_DIGITS
COPY_EXPR_loop:
    ld      r17, Z+
    st      X+, r17
    dec     r16
    brne    COPY_EXPR_loop
    ret

; MAX_SHIFTS(r5:r4: end of Array<BCD, NUM_OPERAND_DIGITS> = read)
; Returns the max amount a number can be shifted
; Returns r18 = NUM_OPERAND_DIGITS - Length of number
MAX_SHIFTS:
    push    YH
    push    YL

    LDPTR   Y
    clr     r16 ; counter
    clr     r17 ; num length
MAX_SHIFTS_loop:
    inc     r16
    clr     r18
    ld      r18, -Y
    cpi     r18, 0
    breq    MAX_SHIFTS_next
    mov     r17, r16
MAX_SHIFTS_next:
    cpi     r16, NUM_OPERAND_DIGITS
    brne    MAX_SHIFTS_loop
    ldi     r18, NUM_OPERAND_DIGITS
    sub     r18, r17

    pop     YL
    pop     YH
    ret

; CLEAR_ARRAY(r5:r4: beginning of Array<BCD, NUM_OPERAND_DIGITS> = read)
; Sets the next NUM_OPERAND_DIGITS to 0
CLEAR_ARRAY:
    push    YH
    push    YL

    LDPTR   Y
    ldi     r16, NUM_OPERAND_DIGITS
CLEAR_ARRAY_loop:
    st      Y+, r2
    dec     r16
    brne    CLEAR_ARRAY_loop

    pop     YL
    pop     YH
    ret

; IS_DIGIT(X: pos in Buf<char> = char to read)
; Returns flag Z = 0 if [X] not in '0' .. '9', otherwise Z = 1
IS_DIGIT:
    ld      r16, X
    subi    r16, '0'
    ; r16 <= 9  <=>  r16 < 10
    cpi     r16, '9' - '0' + 1
    brlo    IS_DIGIT_true
    clz
    rjmp    IS_DIGIT_exit
IS_DIGIT_true:
    sez
IS_DIGIT_exit:
    ret

; CHAR_TO_BCD(X: pos in Buf<char> = read
;             Z: pos in Array<BCD, _> = write)
; Converts char [X] to BCD
; and stores to [Z]
CHAR_TO_BCD:
    ld      r16, X
    subi    r16, '0' ; char -> digit
    st      Z, r16
    ret

; IS_EMPTY(r5:r4: end of Array<BCD, NUM_OPERAND_DIGITS> = read)
; Returns Z = true if the array is empty
IS_EMPTY:
    push    YH
    push    YL

    LDPTR   Y
    ldi     r16, NUM_OPERAND_DIGITS
IS_EMPTY_loop:
    ld      r17, -Y
    cpi     r17, 0
    brne    IS_EMPTY_failure
    dec     r16
    brne    IS_EMPTY_loop
    rjmp    IS_EMPTY_true
IS_EMPTY_failure:
    clz
    rjmp    IS_EMPTY_ret
IS_EMPTY_true:
    sez
IS_EMPTY_ret:

    pop     YL
    pop     YH
    ret

; LOAD_LAST
; Copies the BCD digits from EXPR_LAST to EXPR_RIGHT, using COPY_EXPR
LOAD_LAST:
    ldi     XH, HIGH(EXPR_RIGHT)
    ldi     XL, LOW(EXPR_RIGHT)
    ldi     ZH, HIGH(EXPR_LAST)
    ldi     ZL, LOW(EXPR_LAST)
    call    COPY_EXPR
    ret

; STORE_LAST
; Stores the BCD digits from EXPR_LEFT to EXPR_LAST, using COPY_EXPR
STORE_LAST:
    ldi     XH, HIGH(EXPR_LAST)
    ldi     XL, LOW(EXPR_LAST)
    ldi     ZH, HIGH(EXPR_LEFT)
    ldi     ZL, LOW(EXPR_LEFT)
    call    COPY_EXPR
    ret

; STORE_IF(r5:r4 : beginning of Array<BCD, NUM_OPERAND_DIGITS> = read/write,
;          flag Z: whether to store 0 or 1)
; Stores the flag Z at r5:r4 as a number
STORE_IF:
    brne    STORE_IF_false
    call    CLEAR_ARRAY
    LDPTR   Z
    ldi     r16, 1
    std     Z+NUM_OPERAND_DIGITS-1, r16
    rjmp    COMPARE_SIGNED_ret
    rjmp    STORE_IF_ret
STORE_IF_false:
    call    CLEAR_ARRAY
    rjmp    COMPARE_SIGNED_ret
STORE_IF_ret:
    ret
