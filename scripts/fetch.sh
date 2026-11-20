#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p upstream/parts toolchain
download() {
  local target=$1 url=$2
  if [[ ! -f $target ]]; then
    curl --fail --location --silent --show-error --retry 3 --output "$target.part" "$url"
    mv "$target.part" "$target"
  fi
}

download upstream/remark.pdf https://alpo.ge/remark.pdf
for part in {01..14}; do
  file="lean.tar.gz.part$part"
  download "upstream/parts/$file" "https://alpo.ge/$file"
done

if [[ ! -f upstream/lean.tar.gz ]]; then
  cat upstream/parts/lean.tar.gz.part{01..14} > upstream/lean.tar.gz.part
  mv upstream/lean.tar.gz.part upstream/lean.tar.gz
fi
sha256sum --check evidence/upstream.sha256
gzip --test upstream/lean.tar.gz

if [[ ! -d upstream/extracted/lean ]]; then
  mkdir -p upstream/extracted
  stage=$(mktemp -d upstream/extracted/.stage.XXXXXX)
  tar --no-same-owner --no-same-permissions --extract --gzip --file upstream/lean.tar.gz --directory "$stage"
  mv "$stage/lean" upstream/extracted/lean
  rmdir "$stage"
fi

release=lean-4.33.1-linux.tar.zst
download "toolchain/$release" "https://github.com/leanprover/lean4/releases/download/v4.33.1/$release"
sha256sum --check evidence/toolchain.sha256
if [[ ! -x toolchain/lean-4.33.1-linux/bin/lean ]]; then
  tar --use-compress-program zstd --extract --file "toolchain/$release" --directory toolchain
fi
