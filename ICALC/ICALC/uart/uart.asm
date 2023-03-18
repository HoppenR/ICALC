;
; File: uart/uart.asm
; Author: Christoffer Lundell (chrlu470)
;

; UART_INIT
UART_INIT:
    ; Baud rate
    sts     UBRR0H, r2
    sts     UCSR0A, r2
    ldi     r16, 103
    sts     UBRR0L, r16

    ; Enable transmitter and reciever (also sets bit 2 of transmission size to 0)
    ldi     r16, (1 << RXEN0) | (1 << TXEN0)
    sts     UCSR0B, r16

    ; async, no parity, 1 stop bit, 8 bit transmission:
    ldi     r16, (1 << UCSZ00) | (1 << UCSZ01)
    sts     UCSR0C, r16
    ret

; UART_SEND(r16: char = character to print via UART)
UART_SEND:
    lds     r17, UCSR0A
    sbrs    r17, UDRE0
    rjmp    UART_SEND
    sts     UDR0, r16
    ret
