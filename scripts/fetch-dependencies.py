#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "upstream/extracted/lean"


def git(directory: Path, *args: str, capture: bool = False) -> str:
    result = subprocess.run(
        ["git", "-c", "credential.helper=", "-c", "core.hooksPath=/dev/null",
         "-C", directory, *args],
        check=True,
        stdout=subprocess.PIPE if capture else None,
        text=True,
    )
    return result.stdout.strip() if capture else ""


def fetch(package: dict) -> str:
    name, url, revision = (package[key] for key in ("name", "url", "rev"))
    directory = PROJECT / ".lake/packages" / name
    directory.mkdir(parents=True, exist_ok=True)
    if not (directory / ".git").exists():
        git(directory, "init", "--quiet")
        git(directory, "remote", "add", "origin", url)
    if git(directory, "remote", "get-url", "origin", capture=True) != url:
        raise ValueError(f"{name} has a different origin")
    present = subprocess.run(
        ["git", "-C", directory, "cat-file", "-e", f"{revision}^{{commit}}"],
        capture_output=True,
    ).returncode == 0
    if not present:
        git(directory, "fetch", "--quiet", "--depth", "1", "origin", revision)
    git(directory, "checkout", "--quiet", "--detach", revision)
    return f"{name} {git(directory, 'rev-parse', 'HEAD', capture=True)}"


if __name__ == "__main__":
    manifest = json.loads((PROJECT / "lake-manifest.json").read_text())
    with ThreadPoolExecutor(max_workers=4) as workers:
        for line in workers.map(fetch, manifest["packages"]):
            print(line)
