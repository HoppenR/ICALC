## ICALC

This repository contains two projects that are meant to interface with each other.

1. `ICALC` - a mathematical expression parser and evaluator written in pure
   assembly (see [the project README](./ICALC/README.md)).

2. `calculator_screen` - the graphical front end to the project written in
   python. (see [the project README](./calculator_screen/README.md)).


The project uses a custom protocol, where most printable characters are the
same, but a few non-printable ones have special meaning, as well as there being
one printable character with changed meaning. The following table summarizes
the meaningful changes:

| Char |   Meaning    |
|:----:|:------------:|
|  11  | scroll down  |
|  12  | clear screen |
| 'x'  | square block |

# Why?
ICALC started as a university group project about microcontroller programming,
but when I realized I was the only one doing any work, I took the opportunity to
turn my 400% workload into a fully fledged user-friendly project and put it up
available for anyone to use.
