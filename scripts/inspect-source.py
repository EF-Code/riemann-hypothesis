#!/usr/bin/env python3
from collections import Counter
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1] / "upstream/extracted/lean/src"
IMPORT = re.compile(rb"^[ \t]*(?:(?:public|private|meta|all)[ \t]+)*import[ \t]+(\S+)", re.M)
MARKERS = {
    "axiom declaration": re.compile(rb"^[ \t]*(?:(?:private|public)[ \t]+)?axiom[ \t]+", re.M),
    **{
        word: re.compile(rb"\b" + word.encode() + rb"\b")
        for word in ("sorry", "admit", "sorryAx", "native_decide", "skipKernelTC")
    },
}


def module_name(path: Path) -> str:
    return ".".join(path.relative_to(ROOT).with_suffix("").parts)


def inspect() -> None:
    imports = {}
    counts = Counter()
    for source in ROOT.rglob("*.lean"):
        text = source.read_bytes()
        imports[module_name(source)] = [name.decode() for name in IMPORT.findall(text)]
        counts.update({marker: len(pattern.findall(text)) for marker, pattern in MARKERS.items()})

    pending = ["Main"]
    local = set()
    external = set()
    while pending:
        module = pending.pop()
        if module in local or module in external:
            continue
        if module not in imports:
            external.add(module)
            continue
        local.add(module)
        pending.extend(imports[module])

    print(f"Lean source modules: {len(imports)}")
    print(f"Local modules reachable from Main by source imports: {len(local)}")
    print(f"Direct references to external module names across that graph: {len(external)}")
    for marker in MARKERS:
        print(f"Source matches for {marker}: {counts[marker]}")
    print("These counts report text matches. Axiom dependencies require checking the compiled declarations.")


if __name__ == "__main__":
    inspect()
