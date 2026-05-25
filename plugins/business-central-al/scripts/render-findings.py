#!/usr/bin/env python3
"""Pretty-print a BCQuality findings-report JSON (per the DO meta-skill) into a
human-readable terminal summary.

Usage:
    <al-code-review JSON output> | scripts/render-findings.py
    scripts/render-findings.py path/to/findings.json
"""

import json
import sys
from pathlib import Path

SEV_ORDER = {"blocker": 0, "major": 1, "minor": 2, "info": 3}
SEV_GLYPH = {
    "blocker": "[BLK]",
    "major": "[MAJ]",
    "minor": "[min]",
    "info": "[inf]",
}


def _load() -> dict:
    if len(sys.argv) > 1 and sys.argv[1] not in ("-", "/dev/stdin"):
        return json.loads(Path(sys.argv[1]).read_text())
    return json.load(sys.stdin)


def main() -> None:
    data = _load()
    skill_id = data.get("skill", {}).get("id", "<unknown>")
    outcome = data.get("outcome", "<unknown>")
    reason = data.get("outcome-reason", "")
    counts = data.get("summary", {}).get("counts", {})
    coverage = data.get("summary", {}).get("coverage", {})

    print()
    print(f"=== {skill_id} :: {outcome} ===")
    if reason:
        print(f"  reason: {reason}")
    if counts:
        cnt = " · ".join(f"{k}={v}" for k, v in counts.items() if v) or "0 findings"
        print(f"  counts: {cnt}")
    if coverage:
        we = coverage.get("worklist-size", "?")
        ev = coverage.get("items-evaluated", "?")
        print(f"  coverage: {ev}/{we} items evaluated")
    print()

    findings = data.get("findings", [])
    if not findings:
        print("  (no findings to display)")
    else:
        findings.sort(key=lambda f: (SEV_ORDER.get(f.get("severity"), 99), f.get("id", "")))
        print(f"  Findings ({len(findings)}):")
        for f in findings:
            sev = SEV_GLYPH.get(f.get("severity"), "[?]")
            loc = f.get("location") or {}
            where = ""
            if loc.get("file"):
                where = f" @ {loc['file']}"
                if loc.get("line"):
                    where += f":{loc['line']}"
            from_sub = f.get("from-sub-skill")
            from_str = f" via {from_sub}" if from_sub else ""
            conf = f.get("confidence", "?")
            msg = f.get("message", "")
            if len(msg) > 200:
                msg = msg[:197] + "..."
            print(f"    {sev} ({conf}){from_str}{where}")
            print(f"      {msg}")
            refs = f.get("references", [])
            if refs:
                for r in refs[:3]:
                    p = r.get("path", "?")
                    sha = r.get("sha", "")
                    sha_str = f"@{sha[:7]}" if sha else ""
                    print(f"      ref: {p}{sha_str}")
                if len(refs) > 3:
                    print(f"      ... and {len(refs) - 3} more reference(s)")
            print()

    suppressed = data.get("suppressed", [])
    if suppressed:
        print(f"  Suppressed by layer precedence or configuration ({len(suppressed)}):")
        for s in suppressed:
            ref = s.get("reference", {})
            path = ref.get("path", "?")
            reason = s.get("reason", "?")
            print(f"    - {path}  ({reason})")
        print()

    sub_results = data.get("sub-results", [])
    if sub_results:
        print(f"  Sub-results ({len(sub_results)}):")
        for sr in sub_results:
            sid = sr.get("skill", {}).get("id", "?")
            so = sr.get("outcome", "?")
            sc = sr.get("summary", {}).get("counts", {})
            cnt = " ".join(f"{k}={v}" for k, v in sc.items() if v) or "0 findings"
            print(f"    - {sid:30s} :: {so:18s} {cnt}")
        print()

    skipped = data.get("skipped-sub-skills", [])
    if skipped:
        print(f"  Skipped sub-skills ({len(skipped)}):")
        for sk in skipped:
            sid = sk.get("skill", {}).get("id", "?")
            reason = sk.get("reason", "?")
            print(f"    - {sid}  ({reason})")
        print()


if __name__ == "__main__":
    main()
