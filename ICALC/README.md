# ICALC

## Description
A calculator with arbitrary integer width written in pure ATmega328p assembly.
It supports a custom protocol meant to interface with:
- The `calculator_screen` project.
- A regular serial terminal, though a few characters will not show properly.

## Installation
The file `ICALC/ICALC.atsln` may be opened directly in Microchip Studio or
Atmel Studio that then can be used to program the Arduino.
Alternatively you may program it directly with `AVRDUDE` or similar utilities.

## Usage
Connect the Arduino with a USB-A to USB-B cable, program it and then connect to
it with `calc_screen.py` or a regular serial terminal. From there you will be
able to enter mathematical expressions and see the input and result on the
terminals.

## Why?
- To learn about assembly programming and how to interface it with a user
  friendly front end.

- To learn about low level BCD-array based mathematical expressions and
  operations.

- Because it is fun.

## Troubleshooting
Opening the program in Microchip Studio or Atmel Studio will allow you to step
through the program.
But you will have to enter UART input into the memory manually.
