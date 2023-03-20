;
; File: input_handling/input_handling.asm
; Author: Christoffer Lundell (chrlu470)
;

; INPUT_HANDLER
; Reads the input from the uart module
; Saves valid characters in CHAR_BUF, followed by '\0'
; Mirrors (and formats) the input to display on the output(s)
; Prints "\n\r" to output(s) and exits when user inputs <ENTER>
; Changes pointer X
; Changes pointer Z
INPUT_HANDLER:
    ldi     r19, CHAR_BUF_SZ
    ldi     XH, HIGH(CHAR_BUF)
    ldi     XL, LOW(CHAR_BUF)
INPUT_HANDLER_read_char_loop:
    lds     r16, UCSR0A
    sbrs    r16, RXC0
    rjmp    INPUT_HANDLER_read_char_loop
    lds     r16, UDR0
    call    IS_VALID_CHAR
    brne    INPUT_HANDLER_not_valid
    cpi     r19, 0
    breq    INPUT_HANDLER_read_char_loop
    dec     r19
    call    PRINT_CHAR
    st      X+, r16
    rjmp    INPUT_HANDLER_read_char_loop
INPUT_HANDLER_backspace:
    cpi     r19, CHAR_BUF_SZ
    breq    INPUT_HANDLER_read_char_loop
    ldi     r16, CHAR_BACKSPACE
    call    PRINT_CHAR
    sbiw    X, 1
    inc     r19
    rjmp    INPUT_HANDLER_read_char_loop
INPUT_HANDLER_not_valid:
    cpi     r16, CHAR_BACKSPACE
    breq    INPUT_HANDLER_backspace
    cpi     r16, CHAR_RETURN
    brne    INPUT_HANDLER_read_char_loop
    ldi     r16, '\0'
    st      X, r16
    ldi     r16, '\n'
    call    PRINT_CHAR
    ldi     r16, '\r'
    call    PRINT_CHAR
    ret

; IS_VALID_CHAR(r16: char = user keypress)
; Changes pointer Z
; Returns flag Z = if scancode in VALID_CHARS
IS_VALID_CHAR:
    ldi     ZH, HIGH(VALID_CHARS * 2)
    ldi     ZL, LOW(VALID_CHARS * 2)
IS_VALID_CHAR_loop:
    lpm     r17, Z+
    cpi     r17, '\0'
    breq    IS_VALID_CHAR_false
    cp      r16, r17
    brne    IS_VALID_CHAR_loop
IS_VALID_CHAR_true:
    sez
    rjmp    IS_VALID_CHAR_exit
IS_VALID_CHAR_false:
    clz
IS_VALID_CHAR_exit:
    ret
