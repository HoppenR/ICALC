# ICALC

## Description
A calculator with arbitrary integer width written in pure ATmega328p assembly.
It supports a custom protocol meant to interface with:
- The `calculator_screen` project.
- A regular serial terminal, though a few characters will not show properly.

## Installation
The file `ICALC/ICALC.atsln` may be opened directly in Microchip Studio or Atmel
Studio that then can be used to program the Arduino. Alternatively you may
program it directly with `AVRDUDE` or similar utilities.

## Usage
Connect the Arduino with a USB-A to USB-B cable, program it (see section
"Installation") and then connect to it with `calculator_screen.py` or a regular
serial terminal. From there you will be able to enter mathematical expressions
and see the input and result on the terminals.

## Why
- To learn about assembly programming and how to interface it with a user
  friendly front end.

- To learn about low level BCD-array based mathematical expressions and
  operations.

- To learn about arbitrary expression parsing in an environment where there are
  virtually have no tools to make it easier.

- Because it is fun.

## Features
- [x] Supports mathematical operators: `+`, `-`, `*`, `/`, and `%`.
- [x] Support boolean operators that return 0 or 1: `<`, `>`, and `=`.
- [x] Supports using the answer to the previous expression in a new one
      (character `_`).
- [x] Supports an arbitrary amount of signs before a number.
- [x] Supports an arbitrary amount of operations on a single line.
- [x] Cute startscreen.
- [x] Error handling for when input numbers are too large.
- [ ] Error handling for signed overflow.
- [x] Error handling for division/modulo by 0.
- [x] Subroutines are written in a general manner, and are well documented, making
      them easy to reuse.
- [ ] Operator precedence.
- [ ] Parentheses for prioritizing operations.

## Troubleshooting
Opening the program in Microchip Studio or Atmel Studio will allow you to step
through the program. But you will have to enter UART input into the memory
manually.
