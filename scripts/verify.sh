#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p evidence
project=upstream/extracted/lean
status=evidence/status.log
touch "$status"

run_stage() {
  local label=$1
  shift
  printf '%s %s started\n' "$(date -u +%FT%TZ)" "$label" >> "$status"
  local result=0
  "$@" 2>&1 | tee -a "evidence/$label.log" || result=$?
  printf '%s %s exited %s\n' "$(date -u +%FT%TZ)" "$label" "$result" >> "$status"
  return "$result"
}

if [[ ${1:-} == --check-reduction-first ]]; then
  printf '%s reduction-audit started\n' "$(date -u +%FT%TZ)" >> "$status"
  reduction_result=0
  scripts/check-reduction.sh || reduction_result=$?
  printf '%s reduction-audit exited %s\n' "$(date -u +%FT%TZ)" "$reduction_result" >> "$status"
fi

run_stage build-main scripts/isolated-lean.sh lake --no-cache --no-ansi build +Main:olean
install -m 644 lean/Verify.lean "$project/Verify.lean"
run_stage verify scripts/isolated-lean.sh lake env lean -o .lake/build/lib/lean/Verify.olean Verify.lean
run_stage leanchecker scripts/isolated-lean.sh lake env leanchecker --verbose --fresh Verify
