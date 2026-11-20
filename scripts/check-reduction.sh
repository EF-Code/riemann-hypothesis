#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
project=upstream/extracted/lean
src="$project/src"
mkdir -p "$project/.lake/audit" evidence
audit="$project/.lake/audit/ReductionAudit.lean"

imports=(
  Mathlib.NumberTheory.LSeries.Nonvanishing
  Mathlib.NumberTheory.LSeries.RiemannZeta
  Mathlib.Tactic.GCongr
  Mathlib.Tactic.Linarith
  Mathlib.Tactic.LinearCombination
  Mathlib.Tactic.NormNum
  Mathlib.Tactic.Push
  Mathlib.Tactic.Ring
)

{
  for module in "${imports[@]}"; do printf 'import %s\n' "$module"; done
  printf '\n'

  # Keep the declarations and proof bodies from the archive. Supply only their
  # Mathlib imports and the character nonvanishing proposition from the large branch.
  sed '/^import /d' "$src/Statements.lean"
  sed -n '/^def UpperTheory\.EveryCharacter : Prop :=/{p;n;p;}' \
    "$src/Development/AutomorphicArithmetic/CharacterBoxes/EveryCharacter.lean"
  for relative in Formalism/GammaFactorNonvanishing/{RhOfRight,CritLine}.lean \
    Development/AutomorphicArithmetic/CharacterBoxes/{HalfPlane,ClaimStrip}.lean; do
    printf '\n'
    sed '/^import /d' "$src/$relative"
  done
  printf '\n'
  cat lean/ReductionAuditTail.lean
} > "$audit"

targets=()
for module in "${imports[@]}"; do targets+=("@mathlib/+$module:olean"); done
scripts/isolated-lean.sh lake --no-cache --no-ansi build "${targets[@]}" 2>&1 | tee evidence/build-reduction-deps.log
scripts/isolated-lean.sh lake env lean --tstack=400000 -D autoImplicit=false \
  -D relaxedAutoImplicit=false -D maxSynthPendingDepth=3 -D maxHeartbeats=4000000 \
  .lake/audit/ReductionAudit.lean 2>&1 | tee evidence/reduction-audit.log
