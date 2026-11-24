#!/usr/bin/env python3
"""Validate release-notes entries and gather them into one version's notes.

  release_notes.py validate PATH...
  release_notes.py gather --dir DIR --product {tag,mobi} --version VERSION [--apply]

An entry is DIR/unreleased/<ISSUE-ID>.md:

  ---
  product: mobi, tag, trax or verovia, separated by commas
  type: feature | change | fix
  issue: TAG-123
  audience: users | admins | consultants
  ---
  One to three plain sentences, written for a customer.

A `title` makes a Trax and Verovia highlight: a few paragraphs, the first one
being the line. Only its front matter is checked here; mobi's
`bun run test:shared packages/ai/src/lib/release-notes` checks the rest.
Trax and Verovia release with `bun run release:trax-verovia` in mobi, so
`gather` is for tag and mobi only.
"""

import argparse
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

PRODUCTS = ("mobi", "tag", "trax", "verovia")
GATHER_PRODUCTS = ("tag", "mobi")
TYPES = ("feature", "change", "fix")
AUDIENCES = ("users", "admins", "consultants")
ISSUE_RE = r"^[A-Z][A-Z0-9]+-\d+$"
MAX_BODY_CHARS = 500
MAX_SENTENCES = 3
MAX_TITLE_CHARS = 32
KEYS = ("product", "type", "issue", "audience")
SECTIONS = (("feature", "New"), ("change", "Changed"), ("fix", "Fixed"))


@dataclass
class Entry:
    products: list[str]
    type: str
    issue: str
    audience: str
    body: str
    path: Path
    title: str = ""

    @property
    def line(self) -> str:
        """A highlight's first paragraph is its line."""
        if not self.title:
            return self.body
        first = re.split(r"\n\s*\n", self.body, maxsplit=1)[0]
        return " ".join(part.strip() for part in first.splitlines()).strip()

    def blocks(self, product: str) -> bool:
        """Checked before gathering `product`: its own entries, and any entry
        with a missing or mistyped product, which no release would ever take."""
        return product in self.products or not self.products or any(
            p not in PRODUCTS for p in self.products
        )


def _split(text: str) -> tuple[dict[str, str], str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, text.strip()
    meta = {}
    for index, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            return meta, "\n".join(lines[index + 1:]).strip()
        key, sep, value = line.partition(":")
        if sep:
            meta[key.strip()] = value.strip()
    return meta, ""


def parse_entry(path: Path) -> Entry:
    meta, body = _split(path.read_text(encoding="utf-8"))
    return Entry(
        products=[p.strip() for p in meta.get("product", "").split(",") if p.strip()],
        type=meta.get("type", ""),
        issue=meta.get("issue", ""),
        audience=meta.get("audience", ""),
        body=body,
        path=path,
        title=meta.get("title", ""),
    )


def validate_entry(path: Path) -> list[str]:
    meta, body = _split(path.read_text(encoding="utf-8"))
    entry = parse_entry(path)
    meta["product"] = ", ".join(entry.products)
    problems = [f"missing {key}" for key in KEYS if not meta.get(key)]
    for product in entry.products:
        if product not in PRODUCTS:
            problems.append(f"product must be one of {', '.join(PRODUCTS)}, not {product}")
    if entry.type and entry.type not in TYPES:
        problems.append(f"type must be one of {', '.join(TYPES)}, not {entry.type}")
    if entry.audience and entry.audience not in AUDIENCES:
        problems.append(f"audience must be one of {', '.join(AUDIENCES)}, not {entry.audience}")
    if entry.issue and not re.match(ISSUE_RE, entry.issue):
        problems.append(f"issue must look like TAG-123, not {entry.issue}")
    elif entry.issue and path.name != f"{entry.issue}.md":
        problems.append(f"file name must be {entry.issue}.md")
    if not body:
        problems.append("body is empty")
    elif entry.title:
        if len(entry.title) > MAX_TITLE_CHARS:
            problems.append(f"title is longer than {MAX_TITLE_CHARS} characters")
    else:
        if len(body) > MAX_BODY_CHARS:
            problems.append(f"body is longer than {MAX_BODY_CHARS} characters")
        sentences = len(re.findall(r"[.!?](?=\s|$)", body))
        if sentences > MAX_SENTENCES:
            problems.append(f"body has {sentences} sentences; keep it to {MAX_SENTENCES}")
    return problems


def _natural(issue: str) -> tuple[str, int]:
    prefix, _, number = issue.rpartition("-")
    return prefix, int(number) if number.isdigit() else 0


def _bullet(entry: Entry) -> str:
    prefix = "**For admins:** " if entry.audience == "admins" else ""
    return f"- {prefix}{entry.line}"


def render(entries: list[Entry], version: str) -> str:
    ordered = sorted(entries, key=lambda e: _natural(e.issue))
    blocks = [f"## {version}"]
    for type_, title in SECTIONS:
        items = [e for e in ordered if e.type == type_ and e.audience != "consultants"]
        if items:
            blocks.append(f"### {title}\n\n" + "\n".join(_bullet(e) for e in items))
    consultants = [e for e in ordered if e.audience == "consultants"]
    if consultants:
        blocks.append("### For consultants\n\n" + "\n".join(_bullet(e) for e in consultants))
    return "\n\n".join(blocks) + "\n"


def _cmd_validate(paths: list[str]) -> int:
    failed = False
    for raw in paths:
        for problem in validate_entry(Path(raw)):
            print(f"{raw}: {problem}")
            failed = True
    return 1 if failed else 0


def _cmd_gather(directory: Path, product: str, version: str, apply: bool) -> int:
    unreleased = sorted(
        p for p in (directory / "unreleased").glob("*.md") if p.name != "README.md"
    )
    # An entry with a missing or mistyped product belongs to no product, so it
    # would never be released: it blocks every product until it's fixed.
    problems = [
        (p, problem)
        for p in unreleased
        if parse_entry(p).blocks(product)
        for problem in validate_entry(p)
    ]
    if problems:
        for path, problem in problems:
            print(f"{path}: {problem}", file=sys.stderr)
        return 1
    mine = [p for p in unreleased if product in parse_entry(p).products]
    if not mine:
        print(f"No unreleased entries for {product}.")
        return 0
    print(render([parse_entry(p) for p in mine], version), end="")
    if apply:
        target = directory / version
        target.mkdir(parents=True, exist_ok=True)
        for path in mine:
            shutil.move(str(path), str(target / path.name))
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Release-notes entries")
    sub = parser.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate")
    validate.add_argument("paths", nargs="+")
    gather = sub.add_parser("gather")
    gather.add_argument("--dir", required=True, type=Path)
    gather.add_argument("--product", required=True, choices=GATHER_PRODUCTS)
    gather.add_argument("--version", required=True)
    gather.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    if args.command == "validate":
        return _cmd_validate(args.paths)
    return _cmd_gather(args.dir, args.product, args.version, args.apply)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
