#!/usr/bin/env bash
# ==============================================================================
# Jenkins CI Script: Test Stage (Bats-core)
# ==============================================================================

set -eo pipefail

echo "[TEST] Starting automated testing stage..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p test-results

# Test execution with bats-core
if command -v bats >/dev/null 2>&1; then
    echo "[TEST] Executing Bats test suites..."
    if bats --help | grep -q -- '--formatter'; then
        bats --formatter junit tests/ > test-results/bats-report.xml || bats tests/
    else
        bats tests/
    fi
else
    echo "[TEST] 'bats' command not found on host. Running tests via Alpine Bats container..."
    docker run --rm \
        -v "${REPO_ROOT}:/workspace" \
        -w /workspace \
        bats/bats:latest tests/
fi

echo "[TEST] All test assertions PASSED successfully!"
