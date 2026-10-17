#!/usr/bin/env python3
"""Fail when a customer name appears in files or in a branch's added lines.

Usage: check_customer_names.py [--names-file PATH] [--base REF] [PATH ...]

Names come from, in order: --names-file, the VSD_CUSTOMER_NAMES environment
variable (comma or newline separated), then ~/.config/verosoft/customer-names.txt
(one name per line, # comments). The list is never committed anywhere.

Exit 0: no hits. Exit 1: hits, one "PATH:LINE: NAME" per line (diff hits are
"diff:FILE:LINE: NAME"). Exit 2: no names list found.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Mapping

NO_LIST = (
    "no customer-name list (set VSD_CUSTOMER_NAMES or create "
    "~/.config/verosoft/customer-names.txt)"
)


def _clean(raw: list[str]) -> list[str]:
    names = []
    for item in raw:
        item = item.strip()
        if item and not item.startswith("#"):
            names.append(item)
    return names


def load_names(names_file: str | None, env: Mapping[str, str], home: Path) -> list[str]:
    if names_file:
        return _clean(Path(names_file).read_text(encoding="utf-8").splitlines())
    if env.get("VSD_CUSTOMER_NAMES"):
        return _clean(re.split(r"[,\n]", env["VSD_CUSTOMER_NAMES"]))
    default = home / ".config" / "verosoft" / "customer-names.txt"
    if default.is_file():
        return _clean(default.read_text(encoding="utf-8").splitlines())
    return []


def _patterns(names: list[str]) -> list[tuple[str, re.Pattern]]:
    return [
        (name, re.compile(r"(?<![A-Za-z0-9])" + re.escape(name) + r"(?![A-Za-z0-9])", re.IGNORECASE))
        for name in names
    ]


def find_hits(text: str, names: list[str]) -> list[tuple[int, str]]:
    patterns = _patterns(names)
    hits = []
    for number, line in enumerate(text.splitlines(), start=1):
        for name, pattern in patterns:
            if pattern.search(line):
                hits.append((number, name))
    return hits


def _diff_added_lines(base: str) -> list[tuple[str, int, str]]:
    """Return (file, new line number, text) for each line added since base."""
    out = subprocess.run(
        ["git", "-c", "core.quotePath=false", "diff", "--unified=0", "--no-color", f"{base}...HEAD"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    added = []
    current_file = None
    line_no = 0
    old_left = new_left = 0  # lines still owed by the current hunk
    for line in out.splitlines():
        if old_left or new_left:
            # Inside a hunk every line is content, even one that looks like a header.
            if line.startswith("+"):
                if current_file:
                    added.append((current_file, line_no, line[1:]))
                line_no += 1
                new_left -= 1
            elif line.startswith("-"):
                old_left -= 1
            elif line.startswith(" "):
                line_no += 1
                old_left -= 1
                new_left -= 1
            continue
        if line.startswith("+++ "):
            current_file = line[6:] if line.startswith("+++ b/") else None
        elif line.startswith("@@"):
            match = re.match(r"@@ -\d+(?:,(\d+))? \+(\d+)(?:,(\d+))? @@", line)
            if match:
                old_left = int(match.group(1)) if match.group(1) is not None else 1
                line_no = int(match.group(2))
                new_left = int(match.group(3)) if match.group(3) is not None else 1
    return added


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--names-file")
    parser.add_argument("--base")
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args(argv)

    names = load_names(args.names_file, os.environ, Path.home())
    if not names:
        print(NO_LIST, file=sys.stderr)
        return 2

    hits = []
    if args.base:
        for file, line_no, text in _diff_added_lines(args.base):
            for _, name in find_hits(text, names):
                hits.append(f"diff:{file}:{line_no}: {name}")
    for path in args.paths:
        text = Path(path).read_text(encoding="utf-8", errors="replace")
        for line_no, name in find_hits(text, names):
            hits.append(f"{path}:{line_no}: {name}")

    for hit in hits:
        print(hit)
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
