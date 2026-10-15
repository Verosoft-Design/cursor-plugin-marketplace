---
name: al-profile
description: Find out why something is slow in Business Central with Microsoft's Performance Profiling MCP server (ALTool launchprofilingmcpproxy). Schedules profiling for a session, collect the CPU profiles with SQL/HTTP timings and memory estimate, and explain the hot AL paths against BCQuality performance knowledge. Use for slow pages, posting, job queues or API calls on a real environment. BC 2026 release wave 2 (server 29), preview.
argument-hint: "[session id] [what is slow]"
---

# Profiling a slow BC session

Source: Microsoft Learn, *Scheduled performance profiler: Profiling with an AI agent* and *ALTool: Performance profiling MCP proxy* (2026). Preview: needs a prerelease of runtime 18 and Business Central server version 29.

## 1. Preconditions

- Server 29+, AL Development Tools with `launchprofilingmcpproxy`, and the **Business Central MCP server enabled** for the environment.
- Permission to create profiler schedules and read performance profiles; **D365 ATTACH DEBUG** to profile another user's session.
- The **numeric session ID** of the slow session (an admin finds it in the environment's active sessions; it is also the session ID in telemetry). Ask the user for it.
- While a schedule is active the debugger can't attach to that session (no snapshot debugging at the same time).

## 2. Register the MCP server (once per project)

Add the proxy to the workspace's `.cursor/mcp.json` (merge into an existing `mcpServers` object; show the diff and ask before writing). Credentials never go in `args`: for cloud, sign in once with `altool auth login --environmenttype Sandbox --environmentname <env> --tenant <tenant>` and the proxy reuses the cached token (or set `BC_ACCESS_TOKEN`); for on-prem, `BC_SERVER_USERNAME`/`BC_SERVER_PASSWORD` come from the environment.

```json
{
  "mcpServers": {
    "bc-profiling": {
      "command": "altool",
      "args": ["launchprofilingmcpproxy", "--environmenttype", "Sandbox", "--environmentname", "<env>", "--tenant", "<tenant>"]
    }
  }
}
```

On-prem / container: `"args": ["launchprofilingmcpproxy", "--environmenttype", "OnPrem", "--server", "http://<host>", "--serverinstance", "<BC>", "--port", "7047", "--authentication", "UserPassword"]`. `--port` is the API/OData port (usually 7047), not the dev port (7049). Optional `--profilefolder` (default `%TEMP%/bc-profiling`). Restart Cursor (or reload MCP servers in settings) so the tools load. In VS Code agent mode the AL extension registers this server automatically from `launch.json`; Cursor needs the entry above.

## 3. Capture

1. **Schedule profiling** for the session and activity type (browser, background/job queue, web service), window 5 minutes by default, max 1 hour.
2. Tell the user to do the slow thing now.
3. **Stop schedule and get profiles**: returns `.alcpuprofile` files plus a per-activity overview (durations, SQL and HTTP call counts and times) and the session's estimated memory.
4. Profiles captured elsewhere: put them in the proxy's `user` subfolder and use **Analyze profiles in folder**.

## 4. Explain

- Start from the overview: is the time AL, SQL or HTTP? Many SQL calls with little AL time usually means per-record reads in a loop.
- In the hot AL functions, look for the patterns in `<plugin>/content/bcquality/*/knowledge/performance/` (missing `SetLoadFields`, `FindSet` without filters, `Count` instead of `IsEmpty`, `CalcFields` in loops, `Commit` in loops, unbounded event subscribers) and cite the article.
- Name the object, procedure and line, the evidence (sample share, SQL count), and the fix. Then measure again after the fix: same scenario, compare the overview.

Profiles can contain business data; keep them out of git and delete them when done.
