;
; File: output_handling/startscreen.asm
; Author: Christoffer Lundell (chrlu470)
;

PRINT_STARTSCREEN:
    ldi     ZH, HIGH(STARTSCREEN * 2)
    ldi     ZL, LOW(STARTSCREEN * 2)
    ldi     r16, CHAR_CLEAR
    call    PRINT_CHAR
PRINT_STARTSCREEN_loop:
    lpm     r16, Z+
    cpi     r16, 0
    breq    PRINT_STARTSCREEN_wait_enter
    call    PRINT_CHAR
    rjmp    PRINT_STARTSCREEN_loop
PRINT_STARTSCREEN_wait_enter:
    lds     r16, UCSR0A
    sbrs    r16, RXC0
    rjmp    PRINT_STARTSCREEN_wait_enter
    lds     r16, UDR0
    cpi     r16, '\r'
    brne    PRINT_STARTSCREEN_wait_enter
    ldi     r16, '\n'
    call    PRINT_CHAR
    ldi     r16, '\r'
    call    PRINT_CHAR
    ret

STARTSCREEN:
            .db '\n', '\r'
            .db "   _ _ _   _ _ _   _ _ _ _   _      _ _ ", '\n', '\r'
            .db "  /_/_/_/ /_/_/_/ /_/_/_/_/ /_/    /_/_/", '\n', '\r'
            .db "    /_/   /_/     /_/_ _/_/ /_/    /_/  ", '\n', '\r'
            .db "   /_/   /_/     /_/_/_/_/ /_/    /_/   ", '\n', '\r'
            .db " _ /_/_  /_/_ _  /_/   /_/ /_/_ _ /_/_ _", '\n', '\r'
            .db "/_/_/_/ /_/_/_/ /_/   /_/ /_/_/_/ /_/_/_", '\n', '\r'
            .db '\n', '\r'
            .db "          A SPECIAL PROJECT BY", '\n', '\r'
            .db '\n', '\r'
            .db "           CHRISTOFFER LUNDELL", '\n', '\r'
            .db "          LINKOPING.UNIVERSITY", '\n', '\r'
            .db "            xxxxxx     xxxxxx ", '\n', '\r'
            .db "            xxxxxx     xxxxxx ", '\n', '\r'
            .db "            xxxxxx     xxxxxx ", '\n', '\r'
            .db "            xxxxxx     xxxxxx ", '\n', '\r'
            .db "             xxxxxx   xxxxxx", '\n', '\r'
            .db "               xxxx   xxxx", '\n', '\r'
            .db "        xxxxxx    xxxxx    xxxxx", '\n', '\r'
            .db "     xxxxxxxxxxxxx     xxxxxxxxxxxx ", '\n', '\r'
            .db "   xxxxxxxxx    xxxx xxxx    xxxxxxxx ", '\n', '\r'
            .db "    xxxxx        xxx xxx       xxxxx", '\n', '\r'
            .db "                xxxx xxxx ", '\n', '\r'
            .db "               xxxxx xxxxx", '\n', '\r'
            .db "           xxxxxxxxx xxxxxxxx ", '\n', '\r'
            .db "         xxxxxxxxxx   xxxxxxxxx ", '\n', '\r'
            .db "         xxxxxxx        xxxxxxx ", '\n', '\r'
            .db '\n', '\r'
            .db '\n', '\r'
            .db "       PRESS ENTER TO CONTINUE...", '\0'
