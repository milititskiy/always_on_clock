#!/usr/bin/env python3
"""Generate the original Clock Dots font. Requires fonttools."""

from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen


# Five illuminated columns sit inside a seven-column, nine-row character cell.
PATTERNS = {
    "A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
    "B": ["11110", "11011", "11011", "11110", "11011", "11011", "11110"],
    "C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
    "D": ["11110", "11011", "11011", "11011", "11011", "11011", "11110"],
    "E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
    "F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
    "G": ["01111", "11000", "11000", "11011", "11011", "11011", "01111"],
    "H": ["11011", "11011", "11011", "11111", "11011", "11011", "11011"],
    "I": ["11111", "01110", "01110", "01110", "01110", "01110", "11111"],
    "J": ["00111", "00011", "00011", "00011", "11011", "11011", "01110"],
    "K": ["11011", "11011", "11110", "11100", "11110", "11011", "11011"],
    "L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
    "M": ["10001", "11011", "11111", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "11001", "10101", "10011", "10011", "10001"],
    "O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
    "P": ["11110", "11011", "11011", "11110", "11000", "11000", "11000"],
    "Q": ["01110", "11011", "11011", "11011", "11111", "01110", "00011"],
    "R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
    "S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
    "T": ["11111", "01110", "01110", "01110", "01110", "01110", "01110"],
    "U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
    "V": ["11011", "11011", "11011", "11011", "11011", "01110", "00100"],
    "W": ["10001", "10001", "10101", "10101", "11111", "11011", "10001"],
    "X": ["11011", "11011", "01110", "00100", "01110", "11011", "11011"],
    "Y": ["11011", "11011", "11011", "01110", "00100", "00100", "00100"],
    "Z": ["11111", "00011", "00110", "01100", "11000", "11000", "11111"],
    "0": ["01110", "11011", "11011", "11111", "11011", "11011", "01110"],
    "1": ["00100", "01100", "11100", "01100", "01100", "01100", "11111"],
    "2": ["01110", "11011", "00011", "00110", "01100", "11000", "11111"],
    "3": ["11110", "00011", "00011", "01110", "00011", "00011", "11110"],
    "4": ["11011", "11011", "11011", "11111", "00011", "00011", "00011"],
    "5": ["11111", "11000", "11000", "11110", "00011", "00011", "11110"],
    "6": ["01111", "11000", "11000", "11110", "11011", "11011", "01110"],
    "7": ["11111", "00011", "00110", "00110", "01100", "01100", "01100"],
    "8": ["01110", "11011", "11011", "01110", "11011", "11011", "01110"],
    "9": ["01110", "11011", "11011", "01111", "00011", "00011", "11110"],
    ":": ["00000", "00100", "00100", "00000", "00100", "00100", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "00100", "00100"],
    ",": ["00000", "00000", "00000", "00000", "00100", "00100", "01000"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    "/": ["00001", "00011", "00010", "00100", "01000", "11000", "10000"],
    "'": ["00100", "00100", "01000", "00000", "00000", "00000", "00000"],
    " ": ["00000"] * 7,
}

UPM = 1024  # A 64-unit design grid scaled by 16 for OpenType precision.
PITCH = 80
DOT = 68  # 0.85 of the pitch.
ADVANCE = 7 * PITCH
CAP_HEIGHT = 36 * 16
RADIUS = 10


def dot(pen, x, y):
    r = RADIUS
    pen.moveTo((x + r, y))
    pen.lineTo((x + DOT - r, y))
    pen.qCurveTo((x + DOT, y), (x + DOT, y + r))
    pen.lineTo((x + DOT, y + DOT - r))
    pen.qCurveTo((x + DOT, y + DOT), (x + DOT - r, y + DOT))
    pen.lineTo((x + r, y + DOT))
    pen.qCurveTo((x, y + DOT), (x, y + DOT - r))
    pen.lineTo((x, y + r))
    pen.qCurveTo((x, y), (x + r, y))
    pen.closePath()


def glyph(pattern):
    pen = TTGlyphPen(None)
    for row, bits in enumerate(pattern):
        for column, bit in enumerate(bits):
            if bit == "1":
                dot(pen, (column + 1) * PITCH + (PITCH - DOT) // 2,
                    CAP_HEIGHT - DOT - row * PITCH)
    return pen.glyph()


def build_font(inactive=False):
    patterns = dict(PATTERNS)
    patterns.update({c.lower(): PATTERNS[c] for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"})
    if inactive:
        patterns.update({c: ["11111"] * 7 for c in "0123456789"})
    names = {c: f"uni{ord(c):04X}" for c in patterns}
    glyphs = {".notdef": glyph(["11111", "10001", "10101", "10101", "10101", "10001", "11111"])}
    glyphs.update({names[c]: glyph(pattern) for c, pattern in patterns.items()})

    builder = FontBuilder(UPM, isTTF=True)
    builder.setupGlyphOrder(list(glyphs))
    builder.setupCharacterMap({ord(c): name for c, name in names.items()})
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics({name: (ADVANCE, 0) for name in glyphs})
    builder.setupHorizontalHeader(ascent=48 * 16, descent=-12 * 16)
    family = "Clock Dots Inactive" if inactive else "Clock Dots"
    ps_name = "ClockDotsInactive-Regular" if inactive else "ClockDots-Regular"
    builder.setupNameTable({
        "familyName": family,
        "styleName": "Regular",
        "uniqueFontIdentifier": f"{ps_name}-1.0",
        "fullName": f"{family} Regular",
        "psName": ps_name,
        "version": "Version 1.0",
    })
    builder.setupOS2(
        sTypoAscender=48 * 16, sTypoDescender=-12 * 16, sTypoLineGap=0,
        usWinAscent=48 * 16, usWinDescent=12 * 16,
        sCapHeight=CAP_HEIGHT, sxHeight=CAP_HEIGHT, usWeightClass=700,
    )
    builder.setupPost(isFixedPitch=1)
    builder.setupMaxp()
    filename = "ClockDotsInactive.ttf" if inactive else "ClockDots.ttf"
    output = Path(__file__).resolve().parents[1] / "always_on_clock" / filename
    builder.save(output)
    print(f"Generated {output}")


if __name__ == "__main__":
    build_font()
    build_font(inactive=True)
