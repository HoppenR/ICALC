#!/bin/env python3
from pathlib import Path
from typing import Dict, List

def parse_bitmaps(filename: Path) -> Dict[int, List[bool]]:
    bitmaps: Dict[int, List[bool]] = {}
    with open(filename) as file:
        symbol_segments: List[str] = file.read().split("\n\n")
        for segment in symbol_segments:
            seg_lines: List[str] = segment.splitlines()
            # NOTE: First segment line is like: `-- 65 = 'A'`
            key: int = int(seg_lines[0].split(" ")[1])
            pixels: List[bool] = []
            # NOTE: Remaining segment lines are like: `48*8+0 => b"00111100"`
            for line in seg_lines[1:]:
                pixels += [(x == '1') for x in line.split(" ")[2][2:10]]
            bitmaps[key] = pixels
    return bitmaps
