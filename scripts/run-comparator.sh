#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
project=upstream/extracted/lean
exports="$PWD/upstream/comparator"
reference=.lake/audit/comparator-reference
checker="$PWD/toolchain/lean-4.36.0-linux"
names=(Verification.standardRH Verification.expandedRH Verification.dirichletGRH)
while read -r -a line; do names+=("${line[@]}"); done < lean/comparator-primitives.txt
mkdir -p "$exports" evidence

case "${1:-}" in
  --challenge)
    # Use only artifacts from the pinned dependencies for the reference types.
    dependency_path=$(python - "$project/lake-manifest.json" <<'PY'
import json
from pathlib import Path
import sys
packages = json.loads(Path(sys.argv[1]).read_text())["packages"]
print(":".join(f"/project/.lake/packages/{p['name']}/.lake/build/lib/lean" for p in packages))
PY
)
    mkdir -p "$project/$reference"
    install -m 644 lean/ComparatorChallenge.lean "$project/$reference/ComparatorChallenge.lean"
    scripts/isolated-lean.sh env "LEAN_PATH=$dependency_path" \
      lean -D autoImplicit=false -D relaxedAutoImplicit=false "--root=$reference" -o "$reference/ComparatorChallenge.olean" \
      "$reference/ComparatorChallenge.lean" 2>&1 | tee evidence/compile-challenge.log
    scripts/isolated-lean.sh env "LEAN_PATH=/project/$reference:$dependency_path" \
      /audit-exporter ComparatorChallenge -- "${names[@]}" > "$exports/challenge.export.part"
    mv "$exports/challenge.export.part" "$exports/challenge.export"
    (cd "$exports" && sha256sum challenge.export > challenge.sha256)
    ;;
  --solution)
    (cd "$exports" && sha256sum --check challenge.sha256)
    test -s "$project/.lake/build/lib/lean/Verify.olean"
    scripts/isolated-lean.sh lake env /audit-exporter Verify -- "${names[@]}" > "$exports/solution.export.part"
    mv "$exports/solution.export.part" "$exports/solution.export"
    install -m 644 lean/comparator.json "$exports/comparator.json"
    RH_LEAN_PROJECT="$exports" RH_LEAN_TOOLCHAIN="$checker" \
      scripts/isolated-lean.sh lake comparator --config comparator.json \
      --challenge-from-export challenge.export --solution-from-export solution.export \
      2>&1 | tee evidence/comparator.log
    ;;
  *)
    echo "Usage: $0 --challenge | --solution" >&2
    exit 2
    ;;
esac
