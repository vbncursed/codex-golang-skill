# Performance and Security Guide (Go)

Use this for performance optimization, load resilience, and hardening.

## Performance Workflow

1. Define bottleneck before changing code:
CPU, memory, lock contention, DB latency, network overhead.
2. Baseline with targeted benchmarks:
`go test -bench=. -benchmem ./path/to/pkg`
3. Optimize smallest high-impact hotspot first.
4. Re-measure and report delta in concrete numbers.

## Common Performance Levers

1. Reduce allocations in hot paths (re-use buffers, avoid extra conversions).
2. Bound goroutine fan-out with worker pools or semaphores.
3. Batch database calls and avoid N+1 patterns.
4. Cache safely with explicit invalidation and TTL strategy.

## Security Priorities

1. Validate all external input early.
2. Do not leak sensitive details in logs or error payloads.
3. Keep token/session checks explicit and centralized.
4. Use constant-time comparisons for secrets where applicable.
5. Enforce secure defaults for cookie/session flags and expirations.

## Auth and Session Hotspots

1. Token expiry/refresh edge cases.
2. Session revocation and logout invalidation races.
3. Replay prevention for challenge-based flows.
4. Audit trail completeness for critical auth actions.

## Verification Before Merge

1. Run module tests and vet.
2. Run race checks on changed concurrent paths.
3. If available, run staticcheck and inspect high-confidence issues.
4. Include a short risk note for skipped checks.
