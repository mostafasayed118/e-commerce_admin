# Fast pre-push / CI gate: static analysis + the coverage/consolidation audit.
# Windows twin of tool/check.sh for contributors without git bash.
#
#   ./tool/check.ps1        (or: powershell -File tool/check.ps1)
#
# Runs, in order:
#   1. flutter analyze               — static analysis over the whole repo.
#   2. flutter test test/tool/coverage_audit_test.dart
#                                    — the one-command audit: every lib/
#                                      source referenced by a test (or
#                                      allowlisted with a reason), and no
#                                      duplicated public helpers.
#
# Exits non-zero on the first failure, matching tool/check.sh's contract.
$ErrorActionPreference = 'Stop'

Write-Host '==> flutter analyze'
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> flutter test test/tool/coverage_audit_test.dart'
flutter test test/tool/coverage_audit_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> check passed: analyzer clean, audit green'
