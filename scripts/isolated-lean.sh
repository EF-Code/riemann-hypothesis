#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
project="${RH_LEAN_PROJECT:-$root/upstream/extracted/lean}"
toolchain="${RH_LEAN_TOOLCHAIN:-$root/toolchain/lean-4.33.1-linux}"
build_home="$root/upstream/build-home"
mkdir -p "$build_home"

network=(--unshare-net)
if [[ ${1:-} == --network ]]; then
  shift
  network=(--ro-bind /etc/resolv.conf /etc/resolv.conf)
fi

env_vars=()
for name in HTTPS_PROXY HTTP_PROXY ALL_PROXY NO_PROXY https_proxy http_proxy all_proxy no_proxy; do
  if [[ -n ${!name:-} ]]; then
    env_vars+=(--setenv "$name" "${!name}")
  fi
done

exporter="$root/toolchain/lean4export-v4.33.0/.lake/build/bin/lean4export"
exporter_mount=()
if [[ -x $exporter ]]; then
  exporter_mount=(--ro-bind "$exporter" /audit-exporter)
fi

system_mounts=()
if [[ -d /etc/alternatives ]]; then
  system_mounts=(--ro-bind /etc/alternatives /etc/alternatives)
fi

exec bwrap --unshare-user --unshare-pid --unshare-ipc --unshare-uts --die-with-parent \
  "${network[@]}" "${exporter_mount[@]}" "${system_mounts[@]}" --clearenv "${env_vars[@]}" \
  --ro-bind /usr /usr --symlink usr/bin /bin --symlink usr/lib /lib --symlink usr/lib64 /lib64 \
  --ro-bind /etc/ssl/certs /etc/ssl/certs --proc /proc --dev /dev --tmpfs /tmp \
  --dir /home --dir /root --dir /run/user --dir /var \
  --bind "$project" /project --ro-bind "$toolchain" /lean --bind "$build_home" /build-home \
  --setenv HOME /build-home --setenv PATH /lean/bin:/usr/bin:/bin --setenv LANG C.UTF-8 \
  --setenv LEAN_NUM_THREADS "${RH_LEAN_THREADS:-2}" --chdir /project "$@"
