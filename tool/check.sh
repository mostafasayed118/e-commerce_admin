#!/usr/bin/env bash
#
# Fast pre-push / CI gate: static analysis + the coverage/consolidation audit.
#
#   ./tool/check.sh
#
# Runs, in order:
#   1. flutter analyze               — static analysis over the whole repo.
#   2. flutter test test/tool/coverage_audit_test.dart
#                                    — the one-command audit: every lib/
#                                      source referenced by a test (or
#                                      allowlisted with a reason), and no
#                                      duplicated public helpers.
#
# The full suite (`flutter test`) runs the audit too; this script is the cheap
# early signal for the two contracts that otherwise regress silently. Exits
# non-zero on the first failure, so it slots straight into CI as a pre-gate.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> flutter analyze'
flutter analyze

echo '==> flutter test test/tool/coverage_audit_test.dart'
flutter test test/tool/coverage_audit_test.dart

echo '==> check passed: analyzer clean, audit green'
