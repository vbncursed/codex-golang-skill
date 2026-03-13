---
name: codex-go-mastery
description: Production-focused Go engineering workflow for Codex: implement, refactor, review, debug, and harden Go services with test-first verification and minimal-risk changes. Use when working with Go codebases (especially multi-module repos, gRPC backends, auth/session flows, PostgreSQL/Redis integrations), when asked for a review, or when incidents require fast root-cause analysis with concrete validation commands.
---

# Codex Go Mastery

Deliver safe Go changes with clear validation. Prioritize correctness, behavior preservation, and fast feedback loops.

## Entry Point

Start by classifying the request:

1. `review` or `audit` request:
Use [references/review-checklist.md](references/review-checklist.md).
2. Runtime failures, panics, timeouts, flaky behavior:
Use [references/debug-playbook.md](references/debug-playbook.md).
3. Optimization, load concerns, security hardening:
Use [references/performance-security.md](references/performance-security.md).
4. Multi-module repository changes:
Use `scripts/go_workspace_check.sh` for repeatable validation across modules.

## Standard Workflow

1. Discover scope:
Use `rg --files` and `rg "symbol|error|query|handler"` before editing.
2. Map module boundaries:
Find all `go.mod` files and identify impacted modules only.
3. Implement minimal delta:
Prefer targeted fixes over broad rewrites; preserve APIs unless explicitly requested.
4. Validate locally:
Run formatter and tests in each impacted module.
5. Report risk:
Call out what was validated, what was not, and remaining uncertainty.

## Validation Defaults

Run from each affected module directory:

```bash
find . -type f -name '*.go' -not -path './vendor/*' -exec gofmt -w {} +
go test ./...
go vet ./...
```

Add when relevant:

```bash
go test -race ./...
go test -run TestName -v ./path/to/pkg
go test -bench=. -benchmem ./path/to/pkg
```

For this workspace, common modules are in `auth/` and `gateway/`.

## Go Engineering Guardrails

1. Keep context propagation intact:
Do not replace `context.Context` with globals.
2. Make error paths explicit:
Wrap errors with operation context and avoid swallowing causes.
3. Protect boundaries:
Preserve DTO, storage, and transport contracts unless migration is requested.
4. Avoid hidden behavior changes:
Highlight all semantic changes in auth/session/token logic.
5. Keep changes reviewable:
Small coherent commits and direct test evidence.

## Review Output Contract

When asked to review, output findings first:

1. Severity-ordered issues (`P0` to `P3`)
2. File and line references
3. Behavior impact and failure mode
4. Missing tests or observability gaps

Then provide concise summary and residual risks.

## Bundled Resources

1. `scripts/go_workspace_check.sh`:
Run baseline checks for all or changed Go modules.
2. [references/review-checklist.md](references/review-checklist.md):
Use for review-centric tasks.
3. [references/debug-playbook.md](references/debug-playbook.md):
Use for root-cause and incident debugging.
4. [references/performance-security.md](references/performance-security.md):
Use for performance and hardening tasks.

## Quick Commands

```bash
# List modules and run quick checks
bash scripts/go_workspace_check.sh --list-modules
bash scripts/go_workspace_check.sh --mode quick

# Run only for changed modules (git-tracked changes)
bash scripts/go_workspace_check.sh --changed-only --mode quick

# Full validation including race detector and optional staticcheck
bash scripts/go_workspace_check.sh --mode full
```

If `staticcheck` is unavailable, continue without failing and report that it was skipped.
