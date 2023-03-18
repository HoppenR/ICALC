#!/bin/env python3
from bitmap import parse_bitmaps
from pathlib import Path
from serial import Serial, SerialException
from serial.tools import list_ports
from sys import stderr
from tkinter import Button, Canvas, Event, OptionMenu, PhotoImage, StringVar, Tk
from typing import Dict, List, Union

# ------- BITMAP CONSTANTS -------
BITMAP_FILELOC: Path = Path(__file__).parent.with_name("charset.vhdl")
CHARACTER_SIZE: int  = 8

# ------ PROTOCOL CONSTANTS ------
CHAR_BACKSPACE: int = 8
CHAR_SCROLLDWN: int = 11
CHAR_CLEARSCRN: int = 12

# ------ TERMINAL CONSTANTS ------
BGND_COLOR: str = "#F5F7FA"
TEXT_COLOR: str = "#000000"
CURS_COLOR: str = "#5675B9"
SCRN_NCOLS: int = 40 * CHARACTER_SIZE
SCRN_NROWS: int = 30 * CHARACTER_SIZE

# ----- SERIALPORT SETTINGS  -----
COM_TTIMEOUT: float = 0.2
COM_NRETRIES: int   = 100

# --------- ERROR STRINGS --------
ERR_COM_UNAVAIL: str = "COM '{}' unavailable.\n\tException: {}\n"
ERR_COM_TIMEOUT: str = "COM '{}' timed out. Is the device connected?\n"
ERR_COM_BADMESG: str = "COM '{}' recieved invalid message: {}\n"
ERR_COM_NO_COMS: str = "No COM ports detected\n"

class UI:
    def __init__(self, title: str) -> None:
        ## -------- TKINTER ROOT --------
        self.root: Tk = Tk()
        self.root.geometry('x'.join([str(x) for x in [SCRN_NCOLS, SCRN_NROWS]]))
        self.root.protocol("WM_DELETE_WINDOW", self.quit)
        self.root.resizable(False, False)
        self.root.title(title)

        ## ---- MENU: COMPORT PICKER ----
        self.com_read_callback_id: str
        self.update_button: Button = Button(
                self.root,
                text="Update COM-ports",
                command=self.update_comports
        )
        self.menu_options: List[str] = [""]
        self.menu_selection: StringVar = StringVar()
        self.option_menu: OptionMenu = OptionMenu(
                self.root,
                self.menu_selection,
                *self.menu_options,
                command=self.comport_selected,
        )

        ## ------ SERIAL PORT INFO ------
        self.bad_msg_counter: int = 0
        self.com_port: Serial = Serial(timeout=COM_TTIMEOUT)

        ## ------ CANVAS: TERMINAL ------
        self.bitmaps: Dict[int, List[bool]] = parse_bitmaps(BITMAP_FILELOC)
        self.buffer: bytearray = bytearray()
        self.cursorX: int = 0
        self.cursorY: int = 0
        self.canvas: Canvas = Canvas(
                self.root,
                width=SCRN_NCOLS,
                height=SCRN_NROWS,
                bg=BGND_COLOR,
                highlightthickness=0,
        )
        self.img = PhotoImage(width=SCRN_NCOLS, height=SCRN_NROWS)
        self.canvas.create_image((0, 0), image=self.img, anchor="nw")

        # Prepare user interface for compicker
        self.switch_to_compicker()

    def run(self) -> None:
        self.root.mainloop()

    def reset_screen(self) -> None:
        self.img.blank()
        self.cursorX = 0
        self.cursorY = 0

    def switch_to_compicker(self) -> None:
        self.canvas.pack_forget()
        self.root.bind(sequence="<Escape>", func=self.abort_program)
        self.root.unbind(sequence="<Key>")
        self.com_port.close()
        self.update_button.pack()
        self.option_menu.pack()
        self.update_comports()

    def switch_to_terminal(self) -> None:
        self.option_menu.pack_forget()
        self.update_button.pack_forget()
        self.root.bind(sequence="<Escape>", func=self.abort_to_compicker)
        self.root.bind(sequence="<Key>", func=self.com_write)
        self.buffer.clear()
        self.reset_screen()
        self.canvas.pack()

    def abort_to_compicker(self, _: Event) -> None:
        self.root.after_cancel(self.com_read_callback_id)
        self.switch_to_compicker()

    def abort_program(self, _: Event) -> None:
        self.quit()

    def update_comports(self) -> None:
        self.option_menu.destroy()
        self.menu_options.clear()
        for com in list_ports.comports():
            # NOTE str.split in comport_selected() requires device path to be
            #      the first word before any space
            self.menu_options.append(
                    "{} {}"
                    .format(com.device, com.manufacturer or "- no info -")
            )
        if len(self.menu_options) == 0:
            stderr.write(ERR_COM_NO_COMS)
            return
        self.menu_selection.set("SELECT PORT")
        self.option_menu = OptionMenu(
                self.root,
                self.menu_selection,
                *self.menu_options,
                command=self.comport_selected,
        )
        self.option_menu.pack()

    def comport_selected(self, selection: Union[StringVar, str]) -> None:
        # NOTE: The device path is the first word before any space
        if type(selection) == str:
            self.com_port.port = selection.split(" ", 1)[0]
        elif type(selection) == StringVar:
            self.com_port.port = selection.get().split(" ", 1)[0]
        try:
            self.com_port.open()
        except SerialException as e:
            stderr.write(ERR_COM_UNAVAIL.format(self.com_port.port, e))
            self.update_comports()
            return
        self.switch_to_terminal()
        self.com_read_callback_id = self.root.after_idle(self.com_read)

    def com_write(self, ev: Event) -> None:
        tx: bytes = ev.char.encode("utf-8")
        self.com_port.write(tx)

    def com_read(self) -> None:
        rx: bytes
        try:
            rx = self.com_port.read(1)
        except SerialException as e:
            stderr.write(ERR_COM_UNAVAIL.format(self.com_port.port, e))
            self.switch_to_compicker()
            return
        if len(rx) == 1:
            self.term_apply_msg(rx[0])
            self.bad_msg_counter = 0
        else:
            self.bad_msg_counter += 1
            if self.bad_msg_counter == COM_NRETRIES:
                stderr.write(ERR_COM_TIMEOUT.format(self.com_port.port))
                self.bad_msg_counter = 0
                self.switch_to_compicker()
                return
        self.com_read_callback_id = self.root.after_idle(self.com_read)

    def term_apply_msg(self, msg: int) -> None:
        if msg == CHAR_BACKSPACE:
            # NOTE: Overwriting old cursor before moving around
            #       Old character will be overwritten by draw_cursor at the end
            self.print_char(ord(' '))
            self.buffer.pop()
            self.cursorX -= 2
        elif msg == CHAR_SCROLLDWN:
            self.reset_screen()
            try:
                self.buffer = self.buffer.split(b'\n', 1)[-1]
            except IndexError:
                # NOTE: Got sent scrolldown on first line, ignore
                self.buffer.clear()
            for ch in self.buffer:
                self.print_char(ch)
        elif msg == CHAR_CLEARSCRN:
            self.reset_screen()
            self.buffer.clear()
        elif msg == ord('\r') or msg == ord('\n'):
            # NOTE: Overwriting old cursor before moving around
            self.print_char(ord(' '))
            self.cursorX -= 1
            self.buffer.append(msg)
            self.print_char(msg)
        else:
            self.buffer.append(msg)
            self.print_char(msg)
        self.draw_cursor()

    def print_char(self, ch: int) -> None:
        if ch == ord('\r'):
            self.cursorX = 0
            return
        if ch == ord('\n'):
            self.cursorY += 1
            return
        for x in range(CHARACTER_SIZE):
            for y in range(CHARACTER_SIZE):
                colorset: int
                try:
                    colorset = self.bitmaps[ch][y * CHARACTER_SIZE + x]
                except KeyError as e:
                    stderr.write(ERR_COM_BADMESG.format(self.com_port.port, e))
                    self.cursorX += 1
                    return
                if colorset:
                    self.img.put(
                            data=TEXT_COLOR,
                            to=(self.cursorX * CHARACTER_SIZE + x,
                                self.cursorY * CHARACTER_SIZE + y),
                    )
                else:
                    self.img.put(
                            data=BGND_COLOR,
                            to=(self.cursorX * CHARACTER_SIZE + x,
                                self.cursorY * CHARACTER_SIZE + y),
                    )
        self.cursorX += 1

    def draw_cursor(self) -> None:
        for x in range(CHARACTER_SIZE):
            for y in range(CHARACTER_SIZE):
                self.img.put(
                        data=CURS_COLOR,
                        to=(self.cursorX * CHARACTER_SIZE + x,
                            self.cursorY * CHARACTER_SIZE + y),
                )

    def quit(self) -> None:
        self.com_port.close()
        self.root.destroy()
