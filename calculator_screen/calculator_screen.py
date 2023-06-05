#!/bin/env python3
from ui import UI

'''
     Calculator Screen:
                    - A bitmap-based serial terminal with a simple, easy-to-use
                      graphical interface, built to interface with the arduino
                      ICALC project and understands the custom protocol for it.

     Requirements:
                    - pySerial (pyserial)
                    - TKinter (tk)
                    - Full access to COM-ports
                        If you get "Permission Denied" errors on linux systems
                        you probably need to be in group "uucp" or "dialout"
                    - The file "charset.vhdl" in the parent directory
                        ICALC
                        ├── calculator_screen
                        │   ├── bitmap.py
                        │   ├── calculator_screen.py
                        │   └── ui.py
                        └── charset.vhdl

     Author: Christoffer Lundell (chrlu470)
'''

def main() -> int:
    ui: UI = UI("Calculator")
    ui.run()
    return 0

if __name__ == '__main__':
    exit(main())
