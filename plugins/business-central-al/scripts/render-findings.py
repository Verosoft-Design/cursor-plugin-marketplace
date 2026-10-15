#!/usr/bin/env python3
"""Pretty-print BCQuality output into a human-readable terminal summary.

Accepts any of:
  * a findings-report (DO contract, schemas/findings-report.schema.json), leaf or super-skill;
  * a JSON array of findings-reports (Entry may dispatch several skills);
  * an Entry dispatch record (shown for `no-match` / `failed`, or to explain routing).

Usage:
    <findings JSON> | scripts/render-findings.py
    scripts/render-findings.py path/to/findings.json [--no-code]
"""

import json
import sys
from pathlib import Path

SEV_ORDER = {"blocker": 0, "major": 1, "minor": 2, "info": 3}
SEV_GLYPH = {"blocker": "[BLK]", "major": "[MAJ]", "minor": "[min]", "info": "[inf]"}
CLEAN_OUTCOMES = {"completed", "not-applicable", "no-knowledge"}
MAX_MSG = 300
MAX_CODE_LINES = 12


def _load(args: list[str]):
    paths = [a for a in args if not a.startswith("--")]
    if paths and paths[0] not in ("-", "/dev/stdin"):
        return json.loads(Path(paths[0]).read_text(encoding="utf-8"))
    return json.load(sys.stdin)


def _one_line(text: str, limit: int = MAX_MSG) -> str:
    text = " ".join(str(text).split())
    return text if len(text) <= limit else text[: limit - 3] + "..."


def _where(loc: dict) -> str:
    if not loc or not loc.get("file"):
        return ""
    where = f" @ {loc['file']}"
    if loc.get("line"):
        where += f":{loc['line']}"
        rng = loc.get("range") or {}
        end = rng.get("end-line")
        if end and end != loc["line"]:
            where += f"-{end}"
    return where


def _counts(summary: dict) -> str:
    counts = (summary or {}).get("counts", {})
    parts = [f"{k}={counts.get(k, 0)}" for k in SEV_ORDER if counts.get(k)]
    return " · ".join(parts) or "0 findings"


def render_dispatch(data: dict) -> None:
    print()
    print(f"=== entry :: {data.get('outcome', '<unknown>')} ===")
    if data.get("outcome-reason"):
        print(f"  reason: {data['outcome-reason']}")
    for d in data.get("dispatch", []):
        sk = d.get("skill", {})
        inputs = ", ".join(d.get("inputs", []))
        print(f"  -> {sk.get('id', '?')} ({sk.get('path', '?')}) inputs=[{inputs}]")
        if d.get("rationale"):
            print(f"     {_one_line(d['rationale'], 200)}")
    skipped = data.get("skipped", [])
    if skipped:
        print(f"  Skipped ({len(skipped)}):")
        for s in skipped:
            sk = s.get("skill", {})
            by = s.get("superseded-by", {})
            by_str = f" -> {by.get('id')}" if by.get("id") else ""
            print(f"    - {sk.get('id', '?'):30s} {s.get('reason', '?')}{by_str}")
    print()


def render_finding(f: dict, show_code: bool) -> None:
    sev = SEV_GLYPH.get(f.get("severity"), "[?]")
    conf = f.get("confidence", "?")
    domain = f.get("domain")
    domain_str = f" [{domain}]" if domain else ""
    from_sub = f.get("from-sub-skill")
    from_str = f" via {from_sub}" if from_sub else ""
    agent = " AGENT" if not f.get("references") else ""
    print(f"    {sev} ({conf}){agent}{domain_str}{from_str}{_where(f.get('location') or {})}")
    print(f"      id: {f.get('id', '?')}")
    print(f"      {_one_line(f.get('message', ''))}")
    refs = f.get("references") or []
    for r in refs[:3]:
        sha = r.get("sha", "")
        print(f"      ref: {r.get('path', '?')}{'@' + sha[:7] if sha else ''}")
    if len(refs) > 3:
        print(f"      ... and {len(refs) - 3} more reference(s)")
    if "suggested-code" in f and show_code:
        lines = str(f["suggested-code"]).split("\n")
        print("      suggested-code:")
        for line in lines[:MAX_CODE_LINES]:
            print(f"        | {line}")
        if len(lines) > MAX_CODE_LINES:
            print(f"        | ... ({len(lines) - MAX_CODE_LINES} more line(s))")
    elif f.get("suggested-code-omission-reason"):
        print(f"      no suggested-code: {_one_line(f['suggested-code-omission-reason'], 160)}")
    print()


def render_report(data: dict, show_code: bool) -> None:
    skill = data.get("skill", {})
    skill_id = skill.get("id", "<unknown>")
    version = skill.get("version")
    outcome = data.get("outcome", "<unknown>")
    summary = data.get("summary", {})
    coverage = summary.get("coverage", {})

    print()
    print(f"=== {skill_id}{' v' + str(version) if version else ''} :: {outcome} ===")
    if outcome not in CLEAN_OUTCOMES:
        print("  NOTE: partial/failed is not a clean result; findings may be incomplete.")
    if data.get("outcome-reason"):
        print(f"  reason: {data['outcome-reason']}")
    print(f"  counts: {_counts(summary)}")
    if coverage:
        print(f"  coverage: {coverage.get('items-evaluated', '?')}/{coverage.get('worklist-size', '?')} items evaluated")
    print()

    findings = list(data.get("findings", []))
    if outcome == "failed" and findings:
        print(f"  ({len(findings)} finding(s) ignored: outcome is failed)")
        findings = []
    if not findings:
        print("  (no findings to display)")
        print()
    else:
        findings.sort(key=lambda f: (SEV_ORDER.get(f.get("severity"), 99), f.get("domain") or "", f.get("id", "")))
        by_domain: dict[str, int] = {}
        for f in findings:
            by_domain[f.get("domain") or "-"] = by_domain.get(f.get("domain") or "-", 0) + 1
        print(f"  Findings ({len(findings)}): " + ", ".join(f"{d}={n}" for d, n in sorted(by_domain.items())))
        print()
        for f in findings:
            render_finding(f, show_code)

    suppressed = data.get("suppressed", [])
    if suppressed:
        print(f"  Suppressed knowledge ({len(suppressed)}):")
        for s in suppressed:
            print(f"    - {s.get('reference', {}).get('path', '?')}  ({s.get('reason', '?')})")
        print()

    sub_results = data.get("sub-results", [])
    if sub_results:
        print(f"  Sub-results ({len(sub_results)}):")
        for sr in sub_results:
            sid = sr.get("skill", {}).get("id", "?")
            so = sr.get("outcome", "?")
            cov = sr.get("summary", {}).get("coverage", {})
            cov_str = f" cov={cov.get('items-evaluated', '?')}/{cov.get('worklist-size', '?')}" if cov else ""
            reason = f"  ({_one_line(sr['outcome-reason'], 80)})" if sr.get("outcome-reason") and so not in CLEAN_OUTCOMES else ""
            print(f"    - {sid:28s} :: {so:15s} {_counts(sr.get('summary', {}))}{cov_str}{reason}")
        print()

    skipped = data.get("skipped-sub-skills", [])
    if skipped:
        print(f"  Skipped sub-skills ({len(skipped)}):")
        for sk in skipped:
            print(f"    - {sk.get('skill', {}).get('id', '?')}  ({sk.get('reason', '?')})")
        print()


def render(data, show_code: bool) -> None:
    if isinstance(data, list):
        for item in data:
            render(item, show_code)
        return
    if not isinstance(data, dict):
        raise SystemExit("render-findings: expected a JSON object or array")
    if "dispatch" in data or data.get("skill", {}).get("id") == "entry":
        render_dispatch(data)
    else:
        render_report(data, show_code)


def main() -> None:
    args = sys.argv[1:]
    try:
        data = _load(args)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"render-findings: input is not valid JSON ({exc}); DO requires strict RFC 8259 JSON")
    render(data, show_code="--no-code" not in args)


if __name__ == "__main__":
    main()
