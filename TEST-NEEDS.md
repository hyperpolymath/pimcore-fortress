# TEST-NEEDS.md — pimcore-fortress

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| Zig FFI integration tests | 1 | `ffi/zig/test/integration_test.zig` |
| PHP/Pimcore tests | 2 | Manual test scripts provided |
| Verified stack tests | Present | Shell scripts for validation |

## What's Covered

- [x] Zig FFI integration test suite
- [x] Lithoglyph integration verification
- [x] Container stack validation
- [x] Manual deployment tests

## Still Missing (for CRG B+)

- [ ] Automated Pimcore unit tests
- [ ] PHP property-based testing
- [ ] Performance benchmarks
- [ ] Multi-container test matrix

## Run Tests

```bash
cd /var/mnt/eclipse/repos/pimcore-fortress && ./test-verified-stack.sh
```
