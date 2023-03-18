;
; File: output_handling/output_handling.asm
; Author: Christoffer Lundell (chrlu470)
;

; OUTPUT_HANDLER_INIT
OUTPUT_HANDLER_INIT:
    ldi     r16, 1
    sts     LINE, r16
    ret

; PRINT_CHAR(r16: char = character to print)
; Sends scrolldown to UART if we have reached WINDOW_HEIGHT lines
PRINT_CHAR:
    ; NOTE: If we are sending newline, we should check
    ;       if we need to scroll down first
    cpi     r16, '\n'
    brne    PRINT_CHAR_exit
    lds     r16, LINE
    cpi     r16, WINDOW_HEIGHT
    breq    PRINT_CHAR_scrolldown
    inc     r16
    sts     LINE, r16
    ldi     r16, '\n'
    rjmp    PRINT_CHAR_exit
PRINT_CHAR_scrolldown:
    ldi     r16, CHAR_SCROLLDOWN
    call    UART_SEND
    ldi     r16, '\n'
PRINT_CHAR_exit:
    call    UART_SEND
    ret

; PRINT_RESULT
; Prints (and formats) the contents in EXPR_LEFT, without leading zeroes
; Prints '-' if the number is considered negative
; Prints "ERROR" if the flag Z = 0
; Prints "\n\r" at the end
PRINT_RESULT:
    brne    PRINT_RESULT_error
    ldi     XH, HIGH(EXPR_LEFT)
    ldi     XL, LOW(EXPR_LEFT)
    ldi     r19, NUM_OPERAND_DIGITS
    ldi     r18, '0'
    lds     r16, SIGN
    cpi     r16, '+'
    breq    PRINT_RESULT_leading_zero
    call    PRINT_CHAR
PRINT_RESULT_leading_zero:
    ld      r16, X
    cpi     r16, 0
    brne    PRINT_RESULT_loop
    dec     r19
    breq    PRINT_RESULT_zero
    adiw    X, 1
    rjmp    PRINT_RESULT_leading_zero
PRINT_RESULT_loop:
    ld      r16, X+
    add     r16, r18
    ; NOTE: Sending char in r16 to UART
    call    PRINT_CHAR
    dec     r19
    brne    PRINT_RESULT_loop
    rjmp    PRINT_RESULT_done
PRINT_RESULT_zero:
    ldi     r16, '0'
    call    PRINT_CHAR
    rjmp    PRINT_RESULT_done
PRINT_RESULT_error:
    ldi     r16, 'E'
    call    PRINT_CHAR
    ldi     r16, 'R'
    call    PRINT_CHAR
    ldi     r16, 'R'
    call    PRINT_CHAR
    ldi     r16, 'O'
    call    PRINT_CHAR
    ldi     r16, 'R'
    call    PRINT_CHAR
    rjmp    PRINT_RESULT_done
PRINT_RESULT_done:
    ldi     r16, '\n'
    call    PRINT_CHAR
    ldi     r16, '\r'
    call    PRINT_CHAR
    ret
