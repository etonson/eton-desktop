#!/usr/bin/env python3
"""Render a narrowly scoped, reversible patch to an existing WezTerm config."""
import argparse
from pathlib import Path
import re
import sys

BEGIN = "-- FOREST-RETREAT-COLORS-BEGIN"
END = "-- FOREST-RETREAT-COLORS-END"


def render(original: str, fragment: str) -> str:
    start = fragment.index(BEGIN)
    stop = fragment.index(END) + len(END)
    palette = fragment[start:stop]

    if BEGIN in original or END in original:
        if original.count(BEGIN) != 1 or original.count(END) != 1:
            raise ValueError("Existing Forest Retreat markers are inconsistent")
        old = re.compile(r"^-- FOREST-RETREAT-COLORS-BEGIN\n.*?^-- FOREST-RETREAT-COLORS-END", re.M | re.S)
    else:
        # The current dotfile has a single top-level colors table ending at column 1.
        old = re.compile(r"^config\.colors = \{\n.*?^\}", re.M | re.S)
    if len(old.findall(original)) != 1:
        raise ValueError("Expected exactly one top-level config.colors table")
    result = old.sub(lambda _: palette, original, count=1)

    opacity = re.compile(r"^(config\.window_background_opacity\s*=\s*)(?:0\.\d+|1\.0)([^\n]*)$", re.M)
    if len(opacity.findall(result)) != 1:
        raise ValueError("Expected exactly one window_background_opacity setting")
    result = opacity.sub(lambda m: m.group(1) + "0.96" + m.group(2), result, count=1)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("fragment", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        source = args.source.read_text()
        fragment = args.fragment.read_text()
        args.output.write_text(render(source, fragment))
    except (OSError, ValueError) as exc:
        print(f"WezTerm merge failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
