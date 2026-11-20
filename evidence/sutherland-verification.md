# Review of Sutherland’s verification evidence

Checked on 20 November 2026 against Andrew Sutherland’s status page, last updated at 19:45 UTC. [Verification files](https://math.mit.edu/~drew/grh/)

- The published source archive SHA-256 matches our independently downloaded archive. The listed Lean and Mathlib revisions also match our pinned revisions. [Local archive checksums](upstream.sha256) · [Local dependency revisions](dependencies.txt)
- The published audit script and log identify `riemannHypothesis` in `Main` and `RiemannHypothesis` in Mathlib. The log lists `propext`, `Classical.choice`, and `Quot.sound` as the only dependencies of each of the five headline theorems. [Audit script](https://math.mit.edu/~drew/grh/Audit.lean) · [Audit log](https://math.mit.edu/~drew/grh/audit.log)
- Sutherland reports that all 175,187 project modules passed Lean kernel replay. The Nanoda log records exit status 0, 27 minutes 42 seconds elapsed, about 9.2 CPU-hours, and 84.8 GiB peak resident memory. Our workspace has 8 GiB of RAM. The status page reports a passed Comparator statement and axiom check in one run, with end-to-end Comparator still in progress. [Nanoda log](https://math.mit.edu/~drew/grh/nanoda.log) · [Verification status](https://math.mit.edu/~drew/grh/)
- We checked the audit script, audit log, Nanoda log, Comparator configuration, and compiled-file manifest against the publisher’s checksums. The manifest contains 175,187 distinct module paths. It includes all 220 of our local paths. Of those, 165 have matching hashes and 55 differ. Sutherland used direct `lean` calls and Mathlib’s official cache. Our isolated run used Lake and rebuilt Mathlib from source. The comparison establishes which files match. It leaves the cause of the differences open. [Published checksums](https://math.mit.edu/~drew/grh/SHA256SUMS) · [Local compiled-file checksums](local-project-oleans.sha256)

## Reproduce the comparison

The commands below use the recorded local hashes and download about 29 MB. They run from the repository root and require no Lean build.

```sh
set -eu
review_dir=$(mktemp -d)
trap 'rm -rf "$review_dir"' EXIT
for item in SHA256SUMS Audit.lean audit.log nanoda.log comparator.json project-oleans.sha256; do
  curl -fsSL "https://math.mit.edu/~drew/grh/$item" -o "$review_dir/$item"
done
(cd "$review_dir" && sha256sum --check --ignore-missing SHA256SUMS)

python3 - "$review_dir/project-oleans.sha256" <<'PY'
from pathlib import Path
from sys import argv


def read_manifest(path):
    entries = {}
    for line in Path(path).read_text().splitlines():
        digest, module = line.split('  ', 1)
        if module in entries:
            raise ValueError(f'Duplicate module path: {module}')
        entries[module] = digest
    return entries


published = read_manifest(argv[1])
local = read_manifest('evidence/local-project-oleans.sha256')
common_paths = local.keys() & published.keys()
matches = sum(local[path] == published[path] for path in common_paths)
print(f'Published: {len(published):,}')
print(f'Local: {len(local):,}')
print(f'Matching hashes: {matches:,}')
print(f'Different hashes: {len(common_paths) - matches:,}')
print(f'Missing from published manifest: {len(local) - len(common_paths):,}')
PY
```
