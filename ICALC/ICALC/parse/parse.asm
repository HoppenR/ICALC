;
; File: parse/parse.asm
; Author: Christoffer Lundell (chrlu470)
;

; PARSE_INIT
PARSE_INIT:
    ; Set first ANS to 0
    STADR   EXPR_LAST
    call    CLEAR_ARRAY
    ; Load EXPR_ONE with a 1
    STADR   EXPR_ONE
    call    CLEAR_ARRAY
    ldi     r16, 1
    sts     (EXPR_ONE + NUM_OPERAND_DIGITS - 1), r16
    ret

; PARSE_EXPR
; Entry point of parsing.asm
; Reads data in array CHAR_BUF
; Stores the result in EXPR_LEFT if successful
; Sets Z = 1 when successful. Z = 0 when failure.
PARSE_EXPR:
    ; Re/set default operator
    ldi     r16, '+'
    sts     OPERATOR, r16
    ; Clear LHS
    STADR   EXPR_LEFT
    call    CLEAR_ARRAY
    ; Set X pointer for the parsing
    ldi     XH, HIGH(CHAR_BUF)
    ldi     XL, LOW(CHAR_BUF)
PARSE_EXPR_loop:
    call    PARSE_NUM
    brne    PARSE_EXPR_failure
    adiw    X, 1

    push    XH
    push    XL
    call    PERFORM_OP
    pop     XL
    pop     XH
    brne    PARSE_EXPR_failure

    call    PARSE_OP
    brne    PARSE_EXPR_bad_op
    adiw    X, 1
    rjmp    PARSE_EXPR_loop
PARSE_EXPR_bad_op:
    cpi     r17, '\0'
    breq    PARSE_EXPR_success
PARSE_EXPR_failure:
    clz
    rjmp    PARSE_EXPR_return
PARSE_EXPR_success:
    call    STORE_LAST

    ldi     r16, '+'
    sts     SIGN, r16
    lds     r16, EXPR_LEFT
    cpi     r16, 5
    brlo    PARSE_EXPR_exit
    ldi     r16, '-'
    sts     SIGN, r16
    STADR   EXPR_LEFT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
PARSE_EXPR_exit:
    sez
PARSE_EXPR_return:
    ret

; PARSE_NUM(X: pos in Buffer<Char> = next number to parse)
; Parses the number pointed to by X
; Returns flag Z = false if [X] does not contain a number
; Returns flag Z = false if number overflows
; NOTE: only reads numbers with at most NUM_OPERAND_DIGITS - 1 digits
;       this is to not have to deal with signed integer overflow
; Skips leading spaces
; Changes Y pointer
; Changes Z pointer
; Changes X pointer
PARSE_NUM:
    ; Default sign for numbers
    ldi     r16, '+'
    sts     SIGN, r16
    ; Load arguments for CLEAR_ARRAY
    STADR   EXPR_RIGHT
    call    CLEAR_ARRAY
    ; Load argument for CHAR_TO_BCD
    ldi     ZH, HIGH(EXPR_RIGHT + NUM_OPERAND_DIGITS - 1)
    ldi     ZL, LOW(EXPR_RIGHT + NUM_OPERAND_DIGITS - 1)
    ldi     r18, NUM_OPERAND_DIGITS ; num_digit counter
PARSE_NUM_begin:
    call    IS_DIGIT
    brne    PARSE_NUM_not_digit
PARSE_NUM_valid:
    ; Check if number overflow
    dec     r18
    breq    PARSE_NUM_failure
    ; load arguments for SHIFT_EXPR_TO_LEFT
    STADR   EXPR_RIGHT
    call    SHIFT_EXPR_TO_LEFT
    call    CHAR_TO_BCD
    adiw    X, 1
    call    IS_DIGIT
    breq    PARSE_NUM_valid
    sbiw    X, 1
    rjmp    PARSE_NUM_exit
PARSE_NUM_not_digit:
    ld      r16, X
    cpi     r16, '_'
    breq    PARSE_NUM_load_last
    adiw    X, 1
    cpi     r16, ' '
    breq    PARSE_NUM_begin
    cpi     r16, '+'
    breq    PARSE_NUM_begin
    call    INVERT_SIGN
    cpi     r16, '-'
    breq    PARSE_NUM_begin
PARSE_NUM_failure:
    clz
    rjmp    PARSE_NUM_ret
PARSE_NUM_load_last:
    push    XH
    push    XL
    call    LOAD_LAST
    pop     XL
    pop     XH
PARSE_NUM_exit:
    lds     r16, SIGN
    cpi     r16, '-'
    brne    PARSE_NUM_success
    STADR   EXPR_RIGHT + NUM_OPERAND_DIGITS
    call    TENS_COMPLEMENT
PARSE_NUM_success:
    sez
PARSE_NUM_ret:
    ret

; PARSE_OP
; Parses the operator pointed to by X
; Returns flag Z = false if [X] not in VALID_OPERATORS
; Skips leading spaces
; Changes X pointer (if leading spaces)
; Changes Z pointer
PARSE_OP:
    ld      r17, X
    ldi     ZH, HIGH(VALID_OPERATORS * 2)
    ldi     ZL, LOW(VALID_OPERATORS * 2)
PARSE_OP_loop:
    lpm     r16, Z+
    cpi     r16, '\0'
    breq    PARSE_OP_bad_op
    cp      r16, r17
    breq    PARSE_OP_true
    rjmp    PARSE_OP_loop
PARSE_OP_bad_op:
    cpi     r17, ' '
    brne    PARSE_OP_false
    adiw    X, 1
    rjmp     PARSE_OP
PARSE_OP_false:
    clz
    rjmp    PARSE_OP_exit
PARSE_OP_true:
    sts     OPERATOR, r16
    sez
PARSE_OP_exit:
    ret
