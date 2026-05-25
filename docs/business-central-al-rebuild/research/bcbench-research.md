# BC-Bench Research: Microsoft's SWE-Bench for Business Central (AL)

**Research date:** 2026‑05‑25
**Source:** https://github.com/microsoft/BC-Bench (commit at time of clone: `main`, `pyproject.toml` version `0.5.3`)
**Docs site:** https://microsoft.github.io/BC-Bench/

---

## 1. Executive Summary

**BC‑Bench** is Microsoft's official benchmark for evaluating AI coding agents on real Business Central (AL) development tasks. It is a deliberate port of [SWE‑Bench](https://www.swebench.com/) to the AL ecosystem: 101 tasks mined from real Microsoft BC issues/PRs (`microsoft/BCApps` + `microsoftInternal/NAV`), each task ships a buggy commit + a hidden "gold" patch + a hidden test patch, and the agent's diff is judged purely by whether the **hidden** tests pass against a freshly built BC container.

There are two categories sharing the same dataset:
- **bug‑fix** (101 tasks): standard SWE‑Bench flow — agent reads the bug report, edits AL, hidden tests must pass.
- **test‑generation** (101 tasks): "reversed" SWE‑Bench — agent must write the regression test that fails before the gold patch and passes after.

The harness drives **GitHub Copilot CLI** and **Claude Code** through a unified `bcbench` Python CLI; an "experiment" is any toggle of `instructions / skills / custom agents / MCP servers / model` against a fixed dataset. Results are bootstrapped 5× and published as JSON + a Jekyll leaderboard.

**Headline numbers** (5‑run mean, bootstrap 95% CI; all baseline / no experimental tooling unless noted):

| Category | Best score | Configuration |
|---|---|---|
| bug‑fix | **71.3 %** (70.1‑74.1) | GitHub Copilot · `claude-opus-4.6` · **+ altool MCP** |
| bug‑fix baseline | 67.9 % (65.5‑69.9) | Claude Code · `claude-opus-4-7` (no MCP) |
| bug‑fix Copilot baseline | 67.3 % (66.1‑68.5) | GitHub Copilot · `claude-sonnet-4-6` |
| test‑generation | **62.4 %** (61.2‑63.6) | GitHub Copilot · `claude-opus-4-6` · **+ `ALTest` custom agent** |
| test‑generation baseline | 54.3 % (51.7‑56.8) | GitHub Copilot · `claude-opus-4-7` |

Floor: `gpt-4-1` on Copilot bug‑fix sits at **16.6 %** — i.e. there is a ~50 pt gap between frontier models and gpt‑4 class on AL. Code 4.x Anthropic models dominate the leaderboard for both categories. Adding the **AL MCP server (`altool`)** is worth ~+4 pts on bug‑fix; a domain‑targeted **custom test‑generation agent (`ALTest`) is worth ~+11 pts** on test‑generation.

**For a Cursor AL plugin author**, the actionable takeaways are:
1. **Default to Claude Opus 4.6 / 4.7 or Sonnet 4.6.** GPT‑5 Codex variants are competitive on bug‑fix (~56‑61 %) and faster, but Claude variants lead on the hardest tasks and on test generation. Avoid GPT‑4.1 — it's effectively unusable for AL (16 %).
2. **Bundle the AL MCP** (`Microsoft.Dynamics.BusinessCentral.Development.Tools`, `al launchmcpserver`). It produced the only baseline‑beating bug‑fix result.
3. **Ship a domain agent for test generation.** A ~250‑line `ALTest.agent.md` prompt with strict AL test conventions outperformed any model change for test generation.
4. **Custom instructions / skills as currently checked in are placeholders** — BC‑Bench has not measured a clear win from generic instructions yet, so it's an open research area.
5. **Reuse BC‑Bench's evaluation harness** (`bcbench run …`) to A/B your own Cursor plugin configuration against Claude Code / Copilot baselines on real BC tasks.

---

## 2. Repo structure

```
BC-Bench/
├── src/bcbench/             # Evaluation harness (Python 3.13 + Typer + Pydantic)
│   ├── agent/
│   │   ├── claude/agent.py        # Claude Code subprocess wrapper
│   │   ├── copilot/agent.py       # GitHub Copilot CLI subprocess wrapper
│   │   └── shared/
│   │       ├── config.yaml        # Toggles: instructions/skills/agents/MCP, prompt templates
│   │       ├── mcp.py             # Builds MCP server config for both agents
│   │       ├── prompt.py          # Jinja2 prompt builder
│   │       ├── hooks/             # Tool-usage hook scripts
│   │       └── instructions/<repo-folder>/
│   │           ├── AGENTS.md            # Renamed to copilot-instructions.md / CLAUDE.md
│   │           ├── agents/ALTest.agent.md
│   │           ├── skills/al-test-generation/SKILL.md
│   │           └── instructions/*.instructions.md  (placeholders)
│   ├── dataset/dataset_entry.py   # BugFixEntry / TestGenEntry Pydantic models
│   ├── evaluate/{bugfix,testgeneration}.py   # Per-category pipeline
│   ├── results/                   # Per-category result schema + summaries
│   ├── operations/                # Patch apply, project build, test run, repo setup
│   ├── commands/                  # `bcbench run | evaluate | dataset | result | category`
│   └── cli.py / cli_options.py
├── dataset/
│   ├── bcbench.jsonl              # 101 task rows (shared by bug-fix + test-generation)
│   └── problemstatement/<instance_id>/
│       ├── README.md              # Human-written bug report
│       └── *.png                  # Repro screenshots (when applicable)
├── scripts/                       # PowerShell: BCContainerHelper, build/test, ADO clone
├── evaluator/{scores,metrics}.py  # Braintrust ("bc-eval") scorer hooks
├── docs/                          # Jekyll leaderboard site (microsoft.github.io/BC-Bench/)
│   ├── _data/{bug-fix,test-generation}.json   # Authoritative leaderboard data
│   ├── index.md, bug-fix.md, test-generation.md
├── notebooks/                     # Analysis (overview, claude-vs-copilot, failure analysis, altool & altest comparisons)
├── .github/workflows/             # Evaluation, dataset validation, summarize-results, requeue
├── .devcontainer/devcontainer.json
├── README.md, CATEGORIES.md, EXPERIMENT.md, CONTRIBUTING.md
└── pyproject.toml                 # Currently `version = "0.5.3"`
```

---

## 3. Dataset schema

The dataset (`dataset/bcbench.jsonl`) is a single JSONL with **101 rows** that the two categories interpret differently. The schema is a Pydantic‑validated SWE‑Bench port (`src/bcbench/dataset/dataset_entry.py`).

### 3.1 Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `instance_id` | string | yes | Pattern `<owner>__<repo>-<number>`, e.g. `microsoftInternal__NAV-210528`. Used everywhere as the join key. |
| `repo` | string | yes | `microsoftInternal/NAV` (97 rows) or `microsoft/BCApps` (4 rows). Pattern‑validated `^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$`. |
| `base_commit` | string | yes | 40‑char SHA — the buggy commit the agent runs against. |
| `created_at` | string | yes | ISO date the task was created. |
| `environment_setup_version` | string | yes | BC platform version, pattern `^[0-9]{2}\.[0-9]{1}$`, e.g. `27.0`. Drives BC container image. **Replaces** SWE‑Bench's `environment_setup_commit` + `version`. |
| `project_paths` | string[] | yes | AL project roots touched by the fix (relative paths). Used to enumerate which apps to build/publish. Example: `["App\\Layers\\W1\\BaseApp", "App\\Layers\\W1\\Tests\\SCM"]`. |
| `patch` | string | yes | Gold fix as a unified diff. Hidden from the agent in bug‑fix mode; *shown* in test‑gen "gold-patch" or "both" mode. |
| `test_patch` | string | yes | Gold regression test as a unified diff. Hidden from the agent in test‑gen mode; applied by the harness in bug‑fix mode to evaluate. |
| `FAIL_TO_PASS` | `TestEntry[]` | yes (min 1) | List of `{codeunitID: int, functionName: frozenset[str]}`. The tests that must flip from FAIL → PASS for the task to be "resolved". |
| `PASS_TO_PASS` | `TestEntry[]` | optional | Existing tests that must remain green (regression guard). |
| `metadata.area` | string | no | Functional area tag (`inventory`, `finance`, `sales`, …). |
| `metadata.image_count` | int | no | Number of repro screenshots stored alongside the README. |

Schema differences from SWE‑Bench (called out in `README.md`):
- `environment_setup_commit` and `version` are merged into **`environment_setup_version`**.
- New **`project_paths`** field enumerates AL project roots (build orchestration needs them).
- **`problem_statement`** and **`hints_text`** are *not* stored in JSONL — they live in `dataset/problemstatement/<instance_id>/README.md` plus PNG screenshots, because 67 of 101 tasks include screenshots (mean 4.4 images / task, max 20). The agent receives the README content as its `task` prompt; whether it actually opens the PNGs is up to the agent's tools.

There is also a **W1‑only invariant** enforced at validation time: patches against `BaseApp` may only touch `App/Layers/W1/...` paths (the model validator raises if a non‑W1 layer is modified). This means the benchmark explicitly avoids localization complexity.

### 3.2 Dataset stats

- **101 tasks total** (97 from `microsoftInternal/NAV`, 4 from `microsoft/BCApps`).
- BC platform versions span **24.0 → 27.2** (modal version 27.0 = 51 tasks).
- **20 functional areas** represented; top distribution:

| Area | Count |
|---|---|
| inventory | 21 |
| finance | 19 |
| sales | 12 |
| project | 8 |
| shopify | 7 |
| manufacturing | 5 |
| warehouse | 5 |
| crm / service | 3 each |
| assembly / pricing / purchases / reporting / subscription billing / sustainability / workflow | 2 each |
| eservice / intercompany / utilities / visualization | 1 each |

- **67 of 101 tasks have screenshots** (mean 4.4 images / task) — i.e. ~2/3 of real BC bugs are non‑trivial to describe in plain text. This is a real signal: AL bug reports are visual.

### 3.3 Two sample tasks (real, drawn from the JSONL)

#### Sample A — `microsoftInternal__NAV-210528` (Sustainability)

```jsonc
{
  "metadata": { "area": "sustainability", "image_count": 0 },
  "repo": "microsoftInternal/NAV",
  "instance_id": "microsoftInternal__NAV-210528",
  "base_commit": "1a672853b5e939932b2b9caff994bef826e928ff",
  "created_at": "2025-03-19",
  "environment_setup_version": "26.5",
  "project_paths": [
    "App\\Apps\\W1\\Sustainability\\app",
    "App\\Apps\\W1\\Sustainability\\test"
  ],
  "FAIL_TO_PASS": [
    {
      "codeunitID": 148187,
      "functionName": [
        "VerifyEmissionFieldsMustBeEnabledWhenEnableValueChainTrackingIsEnabled"
      ]
    }
  ],
  "PASS_TO_PASS": [],
  "test_patch": "diff --git a/.../SustCertificateTest.Codeunit.al ...",
  "patch":      "diff --git a/.../SustainabilitySetup.Table.al ... (adds EnableEmissionsWhenValueChainTrackingIsEnabled())"
}
```

Problem statement (`dataset/problemstatement/microsoftInternal__NAV-210528/README.md`):

> **Title: W1 2025 ‑ Bug Bash IV [Sustainability] Value Chain Tracking Enablement**
> ## Repro Steps:
> 1. Open the **Sustainability Setup** page
> 2. Keep all fields in the **Procurement** FastTab disabled
> 3. Enable the **'Enable Value Chain Tracking'** field
>
> ===RESULT=== Only the 'Enable Value Chain Tracking' field has been enabled
>
> ===EXPECTED RESULT=== Enabling this field, it will also enable the following fields if they are not previously enabled: …

Gold fix (visible only in test‑gen "gold-patch" mode): an `OnValidate` extension in `Sustainability Setup.Table.al` that auto‑enables 4 dependent emission flags.

#### Sample B — `microsoftInternal__NAV-220984` (Manufacturing)

> **Title: Report "Exchange Production BOM Item" no longer populates the 'End Date' field of the replaced Item.**
> Repro: replace item 1100 → 70000 via the report; expected: ending date set on replaced line. Regression since BC 25.03.

Gold patch is a one‑character bug fix:
```diff
-      if not ShouldModifyProductionBOMLine then begin
+      if ShouldModifyProductionBOMLine then begin
           ProductionBOMLine."Ending Date" := StartingDate - 1;
           ProductionBOMLine.Modify();
       end;
```
A nice illustration: AL bugs in BC are often single‑token boolean inversions in legacy reports — the test scaffolding in `test_patch` is ~80 lines, the fix is one line.

---

## 4. Categories

There are two **active** categories today; both are execution‑based (judged by running real BC tests in a container). Category metadata lives in `src/bcbench/types.py::EvaluationCategory`.

### 4.1 `bug-fix`

- **Tasks:** 101 (shared dataset).
- **Prompt template** (`src/bcbench/agent/shared/config.yaml::bug-fix-template`): "Fix the issue described below … Do NOT modify any testing logic or test files … Focus on W1 localization."
- **Pipeline** (`src/bcbench/evaluate/bugfix.py`):
  1. Setup workspace, build all `project_paths` in a BC container.
  2. Copy problem‑statement folder into the repo.
  3. Run agent → agent writes a diff.
  4. Revert any test‑file changes (test projects only).
  5. Stage diff, apply the hidden `test_patch`, rebuild, run `FAIL_TO_PASS` + `PASS_TO_PASS`.
  6. Score: `resolution_rate` (all required tests pass) + `build_rate` (compiled).
- **Result class:** `BugFixResult`, fields include `resolved`, `build`, generated patch, error message.

### 4.2 `test-generation` ("reversed SWE‑Bench")

- **Tasks:** same 101.
- **Prompt template:** "Generate ONE NEW test case that reproduces the issue … The tests should fail against the current codebase (unfixed) and should pass once the issue is fixed."
- **Input modes** (`config.yaml::prompt.test-generation-input`, default `"both"`):
  - `problem-statement` — TDD: only the bug report; tests must fail now, pass after the (hidden) fix.
  - `gold-patch` — verification: the gold fix is applied as unstaged changes; the agent must write a test that asserts the fix.
  - `both` — agent sees both. *Default at version 0.5.3.*
- **Pipeline** (`src/bcbench/evaluate/testgeneration.py`):
  1. Setup workspace, build projects, optionally apply `patch` (gold) and/or copy problem statement.
  2. Revert any **app** changes (test code only is allowed).
  3. Extract test functions from the generated patch.
  4. Build & run the agent's tests pre‑patch → must FAIL (otherwise `pre_patch_failed_rate` low).
  5. Apply gold `patch`, rebuild, re‑run → must PASS (`post_patch_passed_rate`).
  6. Score: `resolution_rate` = both transitions correct; plus `build_rate`, `pre_patch_failed_rate`, `post_patch_passed_rate`.

### 4.3 `code-review` — *Coming Soon*

Commented out in the source (`# CODE_REVIEW = "code-review"`). `CATEGORIES.md` explains the architecture for adding a new category: each category needs its own `dataset_path`, `entry_class`, `result_class`, `summary_class`, `pipeline`, and prompt template. A `code-review` category would have its own dataset schema (likely `lm_checklist` style — the codebase already has `Checklist` / `ChecklistAssertion` types with `critical | expected | aspirational` levels suggesting LLM‑judge scoring).

`# EVENT_REQUEST = "event-request"` is also stubbed out as future work.

### 4.4 Headline metrics (uniform across both)

- `ResolutionRate` (core score): fraction of tasks where all required tests transitioned correctly.
- `BuildRate`: fraction where the agent's diff compiled.
- `pass@k = 1 − C(n−c,k) / C(n,k)` — probability of at least one success in k tries.
- `pass^k = C(c,k) / C(n,k)` — probability that all k sampled runs succeed (BC‑Bench publishes **pass^5**).
- 95% bootstrap CI via SciPy `bootstrap`, BCa method, 10000 resamples (`src/bcbench/results/metrics.py`).

---

## 5. Agents Under Evaluation

Two agents are wired in today, both via Python subprocess wrappers that share a single `config.yaml`.

### 5.1 GitHub Copilot CLI

- **Package:** `@github/copilot` (currently pinned at `1.0.39` in `copilot-evaluation.yml`).
- **Auth:** `COPILOT_GITHUB_TOKEN` (PAT). The eval workflow rotates between `COPILOT_PAT`, `COPILOT_PAT2`, `COPILOT_PAT3`, `COPILOT_PAT4` based on job index % 4 to dodge rate limits.
- **Models exposed in the workflow choice list:** `claude-sonnet-4.6`, `claude-haiku-4.5`, `claude-opus-4.6`, `claude-opus-4.7`, `gpt-5.5`, `gpt-5.4`, `gpt-5.3-codex`, `gpt-5.2-codex`, `gpt-5.2`, `gpt-4.1`.
- **Invocation** (`src/bcbench/agent/copilot/agent.py`):
  ```
  copilot --allow-all-tools --disable-builtin-mcps --model={model}
          --log-level=debug --log-dir={out} --prompt={…}
          [--no-custom-instructions]                 # off when instructions disabled
          [--additional-mcp-config={json}]
          [--agent={ALTest}]
  ```
- Instructions folder is copied to `<repo>/.github/`; `AGENTS.md` → `copilot-instructions.md`.

### 5.2 Claude Code

- **Package:** `@anthropic-ai/claude-code` (pinned at `2.1.116` in `claude-evaluation.yml`).
- **Auth:** `ANTHROPIC_API_KEY`.
- **Models exposed:** `claude-sonnet-4-6`, `claude-opus-4-7`, `claude-haiku-4-5` (note hyphens instead of dots — model id quirk).
- **Invocation** (`src/bcbench/agent/claude/agent.py`):
  ```
  claude --output-format=json --strict-mcp-config --model={model}
         --permission-mode=bypassPermissions
         --disallowedTools WebFetch "Bash(curl *)" "Bash(wget *)"
         [--mcp-config={json}] [--agent={ALTest}]
         --print "{prompt}"
  ```
  Note: web‑fetch and curl/wget are blocked so the agent can't accidentally hit live BC services.
- Instructions folder is copied to `<repo>/.claude/`; `AGENTS.md` → `CLAUDE.md`.

### 5.3 What the "agent runner" interface looks like

Each agent module exports a `run_*_agent(entry, model, category, repo_path, output_dir, al_mcp, container_name)` function returning `(AgentMetrics, ExperimentConfiguration)`. The pipeline (`run_agent`) calls it inside a `github_log_group`. To plug in a new agent (e.g. **Cursor CLI**), you would:
1. Add a new `AgentType` enum value with `instruction_filename` and `get_target_dir`.
2. Add a module under `src/bcbench/agent/<your-agent>/` mirroring the `agent.py` + `metrics.py` shape.
3. Add a workflow that installs your CLI, accepts a `model` choice, and calls `bcbench evaluate <your-agent>`.

`ExperimentConfiguration` is what gets persisted on every result so the leaderboard can group by setup:
```python
ExperimentConfiguration(
  mcp_servers=["altool", ...] | None,
  custom_instructions=True | False,
  skills_enabled=True | False,
  custom_agent="ALTest" | None,
)
```

### 5.4 MCP servers currently wired

`src/bcbench/agent/shared/config.yaml` declares the catalog. Today only **one** is enabled in published runs:

| Name | Type | Purpose | Toggle |
|---|---|---|---|
| `altool` | stdio | The official **AL MCP** from `Microsoft.Dynamics.BusinessCentral.Development.Tools` (`al launchmcpserver`). Exposes AL symbols, compile diagnostics, package cache. Programmatically injected with `--assemblyprobingpaths` from BCContainerHelper's compiler folder and `--packagecachepath`. | `--al-mcp` CLI flag (and `mcp.servers` list). |
| `mslearn` | http | `https://learn.microsoft.com/api/mcp` — official Microsoft Learn docs. | Commented out. |
| `filesystem` | stdio | `@modelcontextprotocol/server-filesystem` rooted at the repo. | Commented out. |

The `altool` server is the headline MCP experiment; see §7 for measured impact.

---

## 6. Current results / model recommendations *(as of 2026‑05‑25, BC‑Bench v0.5.3)*

All numbers below come from `docs/_data/bug-fix.json` and `docs/_data/test-generation.json` (the authoritative leaderboard data file). Each row is the mean of **5 full runs** on all 101 tasks, with bootstrap 95% CI.

### 6.1 Bug‑fix leaderboard (baseline, no experimental tooling)

Sorted by mean resolution rate, desc:

| Rank | Agent | Model | Mean | 95% CI | pass^5 | Avg time / task | BC‑Bench ver |
|---|---|---|---|---|---|---|---|
| 1 | Claude Code | claude-opus-4-7 | **67.9 %** | 65.5‑69.9 | 54.5 % | 493 s | 0.5.3 |
| 2 | GitHub Copilot | claude-sonnet-4-6 | 67.3 % | 66.1‑68.5 | 48.5 % | 511 s | 0.4.0 |
| 3 | GitHub Copilot | claude-opus-4-7 | 65.9 % | 64.4‑67.5 | 50.5 % | 245 s | 0.5.1 |
| 4 | GitHub Copilot | claude-opus-4-6 | 66.9 % | 64.6‑69.7 | 45.5 % | 478 s | 0.5.0 |
| 5 | Claude Code | claude-opus-4-6 | 65.7 % | 64.4‑67.1 | 45.5 % | 219 s | 0.5.0 |
| 6 | GitHub Copilot | gpt-5-2-codex | 60.8 % | 59.2‑62.0 | 49.5 % | 196 s | 0.2.2 |
| 7 | GitHub Copilot | claude-opus-4-5 | 59.8 % | 58.2‑61.2 | 38.6 % | 172 s | 0.2.0 |
| 8 | GitHub Copilot | gpt-5-4 | 58.4 % | 55.8‑60.8 | 37.6 % | 314 s | 0.3.1 |
| 9 | GitHub Copilot | claude-opus-4-5 | 58.4 % | 56.6‑60.2 | 38.6 % | 165 s | 0.1.0 |
| 10 | Claude Code | claude-opus-4-5 | 57.4 % | 54.9‑59.2 | 31.7 % | 205 s | 0.1.0 |
| 11 | GitHub Copilot | gpt-5-3-codex | 55.8 % | 54.1‑56.8 | 37.6 % | 107 s | 0.2.1 |
| 12 | GitHub Copilot | gpt-5-1-codex-max | 53.7 % | 51.7‑56.8 | 36.6 % | 229 s | 0.2.2 |
| 13 | GitHub Copilot | **gpt-4-1** | **16.6 %** | 15.6‑17.2 | 5.0 % | 256 s | 0.2.2 |

**Single best published bug‑fix configuration (experimental):**

| Agent | Model | Experiment | Mean | 95% CI | pass^5 |
|---|---|---|---|---|---|
| GitHub Copilot | **claude-opus-4-6** | **`altool` MCP enabled** | **71.3 %** | 70.1‑74.1 | 54.5 % |

That's the only run on the leaderboard that crosses 70 % mean resolution. Compare to the same model with no MCP (66.9 %): **altool MCP ≈ +4.4 points** on Opus 4.6 / Copilot.

### 6.2 Test‑generation leaderboard (baseline)

| Rank | Agent | Model | Mean | 95% CI | pass^5 | Avg time | BC‑Bench ver |
|---|---|---|---|---|---|---|---|
| 1 | GitHub Copilot | **claude-opus-4-7** | **54.3 %** | 51.7‑56.8 | 21.8 % | 214 s | 0.5.1 |
| 2 | GitHub Copilot | claude-opus-4-6 | 51.7 % | 47.5‑58.8 | 22.8 % | 230 s | 0.5.3 |
| 3 | GitHub Copilot | claude-opus-4-5 | 45.5 % | 43.4‑48.9 | 20.8 % | 169 s | 0.1.0 |
| 4 | GitHub Copilot | gpt-5-3-codex | 45.3 % | 42.6‑48.1 | 20.8 % | 155 s | 0.2.2 |
| 5 | GitHub Copilot | gpt-5-2-codex | 44.0 % | 40.8‑48.5 | 16.8 % | 291 s | 0.2.2 |
| 6 | GitHub Copilot | gpt-5-4 | 40.6 % | 38.4‑44.8 | 10.9 % | 301 s | 0.5.2 |

**Single best published test‑generation configuration (experimental):**

| Agent | Model | Experiment | Mean | 95% CI | pass^5 |
|---|---|---|---|---|---|
| GitHub Copilot | claude-opus-4-6 | **`ALTest` custom agent** | **62.4 %** | 61.2‑63.6 | 39.6 % |

A domain‑specific custom agent (`ALTest`, ~250‑line system prompt — see §7.3) lifts Opus 4.6 from 51.7 % → 62.4 %, **~+10.7 points**, and roughly **doubles pass^5** (22.8 → 39.6).

### 6.3 Observed patterns

- **Frontier Anthropic models lead both categories.** Claude Opus 4.6/4.7 + Sonnet 4.6 win bug‑fix; Claude Opus 4.x wins test‑generation.
- **GPT‑5 Codex variants are competitive on bug‑fix** (~56‑61 %) and ~2‑3× faster per task than Claude Opus runs, making them attractive for cost / latency.
- **`gpt-4-1` is functionally broken on AL** (16.6 % bug‑fix). Older models cannot do this work.
- **Claude Code vs GitHub Copilot is within noise on the same model.** E.g. Opus 4.6: Claude Code 65.7 % vs Copilot 66.9 %; the wins from harness choice are smaller than wins from model upgrades or domain tools.
- **AL MCP > model upgrade.** Adding `altool` to Opus 4.6/Copilot (71.3 %) beats *any* baseline configuration in the leaderboard.
- **Custom agent > MCP > baseline for test generation.** ALTest custom agent (62.4 %) > best baseline (54.3 %).
- **Tasks remain noisy.** pass^5 (probability *all 5* runs succeed) for the best baseline is only ~50‑55 % on bug‑fix and ~20‑22 % on test‑generation — i.e. test generation is much less stable, even when the mean looks similar.

### 6.4 Sources / links

- Bug‑fix leaderboard page: https://microsoft.github.io/BC-Bench/bug-fix.html
- Test‑generation leaderboard page: https://microsoft.github.io/BC-Bench/test-generation.html
- Raw data: `docs/_data/bug-fix.json`, `docs/_data/test-generation.json`
- Per‑release notes: each row links to https://github.com/microsoft/BC-Bench/releases/tag/v{version}.

---

## 7. Tooling levers being measured

The whole point of BC‑Bench is to A/B‑test agent setup independently of model. Five levers ride on `src/bcbench/agent/shared/config.yaml`; every result row records exactly which were on via `ExperimentConfiguration`.

### 7.1 `model` (CLI `--model`)

Direct model choice. Workflow `workflow_dispatch.inputs.model` enumerates the allowed slugs per agent (§5). Adding a new model = adding it to `cli_options.py::CopilotModel | ClaudeCodeModel` + workflow choice list. See §6 for measured deltas — model is the single biggest lever; the ~50 point gap between gpt‑4‑1 and Claude Opus 4.7 dwarfs every other knob.

### 7.2 `mcp.servers` (CLI `--al-mcp` flag for the AL MCP)

`mcp.py` builds the JSON `--mcp-config` (Claude) or `--additional-mcp-config` (Copilot) string. The only MCP toggled in published runs is `altool`. The harness handles two BC‑specific snags automatically:
- It injects `project_paths` after `launchmcpserver` (positional args must precede options) and sets `--packagecachepath` from the BCContainerHelper compiler folder.
- It detects `.NET` runtime versions on the host and adds `--assemblyprobingpaths` in the right order (.NET shared before `dlls\` to avoid stale type‑forwarding stubs from things like XrmV91).
- It auto‑writes `runtime` into each app's `app.json` (`platform_major - 11 = runtime_major`) so the AL compiler doesn't enable newer validation rules than the original code expected. (`mcp.py::_set_runtime_version`.)

**Measured impact (bug‑fix, Opus 4.6 / Copilot, 5 runs each):**

| Config | Mean | 95% CI | pass^5 |
|---|---|---|---|
| No MCP | 66.9 % | 64.6‑69.7 | 45.5 % |
| **+ `altool` MCP** | **71.3 %** | **70.1‑74.1** | **54.5 %** |

Delta: **+4.4 mean points, +9 pass^5 points**. CIs do not overlap → effect is statistically meaningful at 95%.

The `altool-comparison.ipynb` notebook codifies the exact comparison (bootstrap, pass@k, pass^k).

### 7.3 `agents.enabled` + `agents.name` (CLI `--agent=…`)

Copies `src/bcbench/agent/shared/instructions/<repo>/agents/` into `.github/agents` (Copilot) or `.claude/agents` (Claude) and passes `--agent=ALTest` to the CLI. The only checked‑in custom agent is **`ALTest`**, intended for the test‑generation category.

`ALTest.agent.md` is a heavily structured ~260‑line prompt that encodes:
- **Role / context** ("you are an AL test automation engineer for Business Central").
- **CRITICAL preservation rule** — never delete/simplify existing test code (it was human‑approved).
- **Test structure rules**: `[Test]`, `[FEATURE] [AI test]`, `[SCENARIO <WorkItemID>]` header, mandatory `Initialize()`, GIVEN/WHEN/THEN comments with blank lines, full variable names.
- **Build‑robustness rules**: prefer adding `[Test]` to an existing codeunit; ≤30‑char object names; reserved object ID ranges; preflight checklist.
- A library catalog (Assert, Library Sales, Library Inventory, Library Variable Storage, …) with prescribed usage rules.
- Forbidden patterns: no `if/else` in test body, no DotNet, no `Commit()` in helpers, no `TestField` for assertions.
- Required patterns: pair `asserterror` with `Assert.ExpectedError() + Assert.ExpectedErrorCode()`; handler procedures only set values, never verify.
- A "common fixes" cookbook with 7 before/after snippets.

**Measured impact (test‑generation, Opus 4.6 / Copilot, 5 runs each):**

| Config | Mean | 95% CI | pass^5 |
|---|---|---|---|
| Default | 51.7 % | 47.5‑58.8 | 22.8 % |
| **+ `ALTest` custom agent** | **62.4 %** | **61.2‑63.6** | **39.6 %** |

Delta: **+10.7 mean points, +16.8 pass^5 points**. CIs barely overlap and pass^5 nearly doubles. This is the largest tooling delta measured to date in BC‑Bench.

The `altest-comparison.ipynb` notebook codifies the comparison.

### 7.4 `skills.enabled` (currently no published evidence)

Copies `instructions/<repo>/skills/` into `.github/skills` (Copilot) or `.claude/skills` (Claude). The checked‑in skill is `al-test-generation/SKILL.md` — a much shorter, top‑level "how to write AL tests" guide focused on identifying required handlers, TableRelation validation, AAA structure, and handler signatures.

`skills.enabled` does *not* appear with `true` in any published result, so we have no measured delta for skills alone.

### 7.5 `instructions.enabled` (currently no published evidence)

Copies the **entire** `instructions/<repo>/` folder (AGENTS.md + skills + agents + per‑object instructions). When false, the harness passes `--no-custom-instructions` to Copilot.

The checked‑in `AGENTS.md` is a substantive 45‑line BC primer (W1 vs localizations, layered architecture, BaseApp / first‑party apps / system app, "focus on W1 unless told otherwise"). However the per‑object `instructions/codeunits.instructions.md`, `pages.instructions.md`, `tables.instructions.md` are **empty placeholders** (5‑line stubs). EXPERIMENT.md explicitly notes "The files checked in today are placeholders. Replace them with whatever you want to test."

`custom_instructions: true` does not appear in any published result. **Generic AL instructions remain an open research area in BC‑Bench.**

### 7.6 Summary of measured tooling impact

| Lever | Published evidence | Best measured effect |
|---|---|---|
| Model choice | Yes, all 10+ models on bug‑fix | **+51 pt** (gpt‑4‑1 → claude‑opus‑4‑7) |
| AL MCP (`altool`) | Yes (bug‑fix, Opus 4.6) | **+4.4 pt** mean, +9 pass^5 |
| Custom agent (`ALTest`) | Yes (test‑gen, Opus 4.6) | **+10.7 pt** mean, +16.8 pass^5 |
| Skills only | No | — |
| Custom instructions only | No | — |

---

## 8. Reproducing the benchmark locally

### 8.1 Prereqs

- **OS:** Windows is the canonical environment (the harness uses BCContainerHelper + PowerShell). A Linux/macOS devcontainer (`.devcontainer/devcontainer.json` → `mcr.microsoft.com/devcontainers/python:3.13` with PowerShell + uv + ruby/jekyll) covers the *harness*, but you cannot actually build BC containers there — you need Windows + Docker + BCContainerHelper for the build/test pipeline.
- **Tools:** `uv` (Python), `gh` CLI, `git`, Node 24 (for `@github/copilot` or `@anthropic-ai/claude-code`), `dotnet` (for `Microsoft.Dynamics.BusinessCentral.Development.Tools` if you want AL MCP). The eval workflows hardcode versions: Copilot CLI `1.0.39`, Claude Code `2.1.116`, AL tool `17.0.33.55542`.
- **Auth:** `COPILOT_PAT` and/or `ANTHROPIC_API_KEY`. To clone NAV from ADO you also need an `ADO_TOKEN`.

### 8.2 First setup

```bash
gh repo fork microsoft/BC-Bench --clone   # or git clone if you only want to read
cd BC-Bench

uv python install                          # Python 3.13
uv sync --all-groups                       # installs bcbench + analysis + dev groups
uv run pre-commit install
uv run bcbench --help

cp .env.sample .env                        # then fill in:
#   ADO_TOKEN, BC_CONTAINER_NAME, BC_CONTAINER_USERNAME, BC_CONTAINER_PASSWORD
```

### 8.3 Configure an experiment

Edit `src/bcbench/agent/shared/config.yaml`:
- Toggle `instructions.enabled`, `skills.enabled`, or `agents.enabled` + `agents.name` as needed.
- Drop replacement files under `src/bcbench/agent/shared/instructions/microsoftInternal-NAV/{AGENTS.md, agents/, skills/, instructions/}`.
- Uncomment / add MCP servers under `mcp.servers`. The harness already knows about `altool` (toggle with `--al-mcp`), `mslearn`, and `filesystem`.

Optional: switch test‑gen input mode by editing `prompt.test-generation-input` to `problem-statement | gold-patch | both` (default `both`).

### 8.4 Smoke test on one task

This generates a patch only (no BC container needed):

```bash
uv run bcbench run copilot microsoft__BCApps-5633 \
  --category bug-fix \
  --repo-path /path/to/BCApps
```

Or Claude Code:

```bash
uv run bcbench run claude microsoftInternal__NAV-210528 \
  --category test-generation \
  --repo-path /path/to/NAV \
  --al-mcp
```

The CLI also exposes `bcbench category list | show`, `bcbench dataset …` (validate, list), `bcbench evaluate <agent> …` (the end‑to‑end run that includes BC container build/test), and `bcbench result update | summarize | display`.

### 8.5 Full eval

The canonical way is to push your config changes to a fork and trigger the `Evaluation with GitHub Copilot` / `Evaluation with Claude Code` workflow from the Actions tab. Inputs:

- `model` — pick from the workflow's choice list (`claude-opus-4.7` is the current default frontier).
- `category` — `bug-fix` or `test-generation`.
- `test-run: true` — runs 4 entries in ~10 min, recommended before any full run.
- `al-mcp: true | false`.
- `repeat: "1".."5"` — re‑runs the full 101 sequentially. **Microsoft uses `5`** for everything on the leaderboard.

Workflow does: `get-entries` → `evaluate-with-{copilot,claude}-cli` (matrixed over 32 / 24 parallel BC containers on self‑hosted Windows runner `GitHub-BCBench`) → `summarize-results` (writes a row into `docs/_data/<category>.json` on a `leaderboard/<…>` branch) → optional `requeue` to repeat. Merge that branch to publish.

To run on a fork you must replace the `GitHub-BCBench` self‑hosted runner label with a standard label, remove the `ado-read` environment, set `COPILOT_PAT` / `ANTHROPIC_API_KEY` repo secrets, and remove the Braintrust upload step (see CONTRIBUTING.md §"After Forking").

### 8.6 Inspecting results

- Artifacts are JSONL files per `instance_id` under `evaluation_results/`.
- `notebooks/result/<category>/` contains per‑run notebooks; `notebooks/aggregate-result/<category>/` contains the aggregate notebooks.
- `notebooks/bug-fix/{overview,claude-vs-copilot,altool-comparison,failure-analysis}.ipynb` and `notebooks/test-generation/{overview,altest-comparison}.ipynb` are the published analysis templates.

---

## 9. The CI / Validation workflow

`.github/workflows/dataset-validation.yml` runs **weekly** (`cron: "0 0 * * 0"`) and on‑demand. For each task (or only modified ones), it:

1. Checks out the BC‑Bench repo.
2. Uses the composite action `setup-bc-container-repo` to clone the upstream BC repo at the right `base_commit` and spin up a BC container at the right `environment_setup_version`.
3. Runs `scripts/Verify-BuildAndTests.ps1 -InstanceId … -RepoPath …` — this applies the gold `patch` + `test_patch` to the buggy commit and asserts that:
   - Everything builds.
   - All `FAIL_TO_PASS` tests pass.
   - All `PASS_TO_PASS` tests still pass.

In other words it continuously verifies that **every dataset row remains a valid SWE‑Bench‑style task** despite upstream BC compiler / BCContainerHelper / dotnet tool changes. This is what prevents the dataset from silently rotting.

`CI.yml` is a lighter PR check: lint + pytest + a random‑category, 4‑entry mock evaluation (no real agent, no BC container) to catch harness regressions.

---

## 10. Concrete recommendations for the Cursor AL plugin

Based purely on what BC‑Bench has actually measured:

1. **Default model recommendation: Claude Opus 4.7 (or Sonnet 4.6 for cost / speed).**
   - Opus 4.7 is at the top of both leaderboards.
   - Sonnet 4.6 is within 0.6 pt of Opus 4.7 on bug‑fix at significantly different cost. For day‑to‑day BC dev tasks the cheaper choice is hard to beat.
   - For very tight latency budgets, `gpt-5-3-codex` is the fastest competitive option (107 s / task vs ~250‑500 s for Claude Opus), 55.8 % bug‑fix.
   - Block / warn against `gpt-4.1` style models — they are not viable for AL (16.6 %).

2. **Bundle the official AL MCP by default.** This is the single highest‑ROI piece of infrastructure on the leaderboard.
   - Server: `al launchmcpserver --transport stdio --packagecachepath … --assemblyprobingpaths …` from `Microsoft.Dynamics.BusinessCentral.Development.Tools` (v17+).
   - Replicate BC‑Bench's setup tricks: inject `project_paths` after `launchmcpserver`, detect .NET runtime and add `.NET shared` paths *before* the `dlls\` folder, and write `runtime` into each `app.json` so older code keeps compiling cleanly.
   - Reference impl: `src/bcbench/agent/shared/mcp.py` is ~180 lines and is a near‑drop‑in template.

3. **Ship a "Write AL Test" mode that activates a domain agent prompt.** The biggest measured tooling win in BC‑Bench (+10.7 pt) is a structured `ALTest.agent.md` system prompt.
   - At minimum: AAA / GIVEN‑WHEN‑THEN structure, mandatory `Initialize()`, library catalog, forbidden patterns (no `if/else` in test body, no `TestField` for assertions, no DotNet), required patterns (`Assert.ExpectedError + Assert.ExpectedErrorCode` after `asserterror`).
   - The full prompt lives at `src/bcbench/agent/shared/instructions/microsoftInternal-NAV/agents/ALTest.agent.md` — it's MIT‑licensed and ready to adapt.

4. **Ship a top‑level `AGENTS.md` that explains layered BC architecture.** BC‑Bench's `AGENTS.md` (`src/bcbench/agent/shared/instructions/microsoftInternal-NAV/AGENTS.md`) tells agents: System Application is a submodule (do not edit), BaseApp is the core, Apps/W1 are first‑party extensions, **focus on W1 unless explicitly otherwise**. Even without a measured delta, this is exactly the implicit knowledge most agents lack.

5. **Adopt BC‑Bench's exact dataset & harness for your own plugin evaluation.** The whole pipeline is open source, MIT, and supports plug‑in agents:
   - Fork BC‑Bench, add a `cursor` agent module mirroring `claude/agent.py`'s ~80‑line shape (invoke your Cursor CLI in non‑interactive mode, parse JSON output for metrics).
   - Run the workflow with `repeat: 5` and your model under test → produces directly comparable numbers vs Claude Code / Copilot.
   - If you don't have Windows runners, you can still smoke test with `bcbench run cursor <instance_id> --category bug-fix --repo-path <BCApps>` which only generates a patch.

6. **Watch the `code-review` category.** It's tagged "Coming Soon"; once it lands it will likely use `Checklist`‑style LLM‑judge scoring (already stubbed in the code). A Cursor plugin emphasizing PR review will want to be on the leaderboard for that one early.

7. **Don't oversell "AI test generation"** in marketing. Even with the ALTest custom agent + Opus 4.6, only **39.6 %** of tasks pass all 5 runs (pass^5). Test generation in real BC code is genuinely hard; honest UX (showing confidence, requiring human review) will beat overconfident UX.

---

## 11. Open questions / data gaps

- **Skills‑only and custom‑instructions‑only impact is unmeasured.** No published row has `skills_enabled: true` or `custom_instructions: true`. We don't know whether `applyTo`‑style per‑object instructions (currently empty placeholder files) actually help — this is a real research opportunity.
- **No published `altool` ablation for non‑Opus‑4.6 models.** We don't yet know whether `altool` MCP helps GPT‑5 Codex models, Claude Sonnet, or Claude Code (the AL MCP is wired but only one full‑repeat config has been published with it on).
- **No published `mslearn` MCP results.** Microsoft Learn MCP is wired but commented out — its potential effect on niche / older‑API questions is unknown.
- **No Cursor / Cursor CLI baseline.** The harness only supports Copilot and Claude Code today; running a Cursor baseline would require a fork.
- **101 tasks is small.** SWE‑Bench Verified is 500. BC‑Bench's CI is a structural correctness net (every row still works), but the bus factor on individual tasks is real — flaky tasks (passing in some runs, failing in others) are explicitly studied in `notebooks/bug-fix/failure-analysis.ipynb`. Treat pass^5 as the more honest number than mean.
- **Bug categories are concentrated.** 21 % of tasks are inventory, 19 % finance, 12 % sales — three areas account for >50 % of the benchmark. Performance on rarer areas (sustainability, intercompany, eservice) may not be well characterized.
- **Future models are listed but not yet measured.** `gpt-5.5`, `gpt-5.4`, `gpt-5.2`, `claude-haiku-4.5` appear in the Copilot workflow choice list but have no published rows yet (as of v0.5.3). Watch the next BC‑Bench releases for those.
- **All tasks are W1 only by design.** Localization (US, DE, DK, APAC, …) bugs are explicitly outside scope. A Cursor plugin targeting localization customers cannot rely on BC‑Bench numbers for that segment.

---

## Citations

- README: https://github.com/microsoft/BC-Bench/blob/main/README.md
- CATEGORIES.md: https://github.com/microsoft/BC-Bench/blob/main/CATEGORIES.md
- EXPERIMENT.md: https://github.com/microsoft/BC-Bench/blob/main/EXPERIMENT.md
- CONTRIBUTING.md: https://github.com/microsoft/BC-Bench/blob/main/CONTRIBUTING.md
- Leaderboard site: https://microsoft.github.io/BC-Bench/
- Bug‑fix leaderboard: https://microsoft.github.io/BC-Bench/bug-fix.html
- Test‑generation leaderboard: https://microsoft.github.io/BC-Bench/test-generation.html
- Raw leaderboard data: `docs/_data/bug-fix.json`, `docs/_data/test-generation.json`
- AL MCP package: https://www.nuget.org/packages/Microsoft.Dynamics.BusinessCentral.Development.Tools
- GitHub Copilot CLI: https://github.com/github/copilot-cli
- Claude Code: https://docs.anthropic.com/en/docs/claude-code
- Original SWE‑Bench: https://github.com/swe-bench/SWE-bench
