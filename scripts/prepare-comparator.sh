#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
release=lean-4.36.0-linux.tar.zst
release_sha=2b7ab1ed8b92d2e6abfaf41344823b510064dbc9c0260cac73eb496ab2dea6eb
exporter="$PWD/toolchain/lean4export-v4.33.0"
exporter_rev=15f6055e299ad5b89345e533cc2192f4cc00f659
mkdir -p toolchain

if [[ ! -f toolchain/$release ]]; then
  curl -fLSs --retry 2 -o "toolchain/$release.download" \
    "https://github.com/leanprover/lean4/releases/download/v4.36.0/$release"
  mv "toolchain/$release.download" "toolchain/$release"
fi
printf '%s  %s\n' "$release_sha" "toolchain/$release" | sha256sum --check
if [[ ! -x toolchain/lean-4.36.0-linux/bin/lake ]]; then
  tar -I zstd -xf "toolchain/$release" -C toolchain
fi

if [[ ! -d $exporter/.git ]]; then
  git -c credential.helper= -c core.hooksPath=/dev/null clone --quiet --depth 1 \
    --branch v4.33.0 https://github.com/leanprover/lean4export "$exporter"
fi
test "$(git -C "$exporter" rev-parse HEAD)" = "$exporter_rev"
RH_LEAN_PROJECT="$exporter" scripts/isolated-lean.sh lake --no-cache --no-ansi build lean4export
