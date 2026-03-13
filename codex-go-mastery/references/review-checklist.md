# Go Review Checklist

Use this when the user asks for a code review or audit.

## Scope First

1. Identify modified packages and exported API deltas.
2. Confirm whether behavior changes are intentional.
3. Check migration requirements for config/schema/protocol changes.

## Correctness

1. Validate nil handling and zero-value behavior.
2. Verify error handling and wrapping (`fmt.Errorf("...: %w", err)`).
3. Check for ignored errors from I/O, db, json, and network operations.
4. Confirm map/slice bounds safety and defensive parsing.

## Concurrency

1. Ensure goroutine lifetime is bounded by context or explicit stop signal.
2. Check channel close ownership and send-on-closed risks.
3. Detect data races on shared state and cache structures.
4. Verify `sync.Mutex` usage does not permit lock inversion.

## API and Contracts

1. Verify backward compatibility for protobuf/JSON fields.
2. Ensure DTO mapping does not drop security-critical fields.
3. Confirm auth/session/token semantics remain unchanged unless requested.

## Data and Storage

1. Check transaction boundaries and rollback behavior on partial failure.
2. Verify SQL queries for placeholder correctness and scan destination order.
3. Confirm Redis key structure, TTL behavior, and invalidation logic.

## Testing Expectations

1. New branch or bugfix should include focused tests.
2. Edge-case coverage for empty input, timeout, and upstream errors.
3. For concurrency-sensitive code, require race checks on touched packages.

## Review Output Format

1. Findings by severity (`P0`..`P3`).
2. Each finding includes: path, line, impact, repro/failure mode, and fix direction.
3. Mention residual risk and missing validation at the end.
