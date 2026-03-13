# Go Debug Playbook

Use this when debugging runtime incidents or unstable behavior.

## 1. Triage

1. Capture exact symptom:
panic, timeout, high latency, incorrect response, memory growth, or auth failure.
2. Isolate first failing boundary:
transport (gRPC/HTTP), service logic, storage (Postgres/Redis), external call.
3. Build a minimal repro:
specific endpoint/RPC, payload, and expected vs actual result.

## 2. Error-Path Inspection

1. Trace error origin through wrapped errors.
2. Verify context deadlines and cancellation propagation.
3. Confirm no dropped errors in deferred cleanup and writer flushes.

## 3. Transport and API Checks

1. Verify status mapping from internal errors to gRPC/HTTP codes.
2. Confirm request validation and edge-case payload handling.
3. Check versioning compatibility for protobuf fields.

## 4. Data Layer Checks

1. Validate SQL query semantics and transaction boundaries.
2. Inspect connection pool pressure and timeout settings.
3. Verify Redis serialization/deserialization and TTL assumptions.

## 5. Concurrency and Resource Leaks

1. Identify unbounded goroutines.
2. Check channel producers/consumers for deadlock risks.
3. Run race detector on touched packages if synchronization changed.

## 6. Confirm Fix

1. Add or update a test that fails before and passes after.
2. Re-run module checks:
`go test ./...` and `go vet ./...`.
3. Document residual uncertainty:
what was not validated and why.
