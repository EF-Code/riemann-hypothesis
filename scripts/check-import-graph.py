#!/usr/bin/env python3
from pathlib import Path
from subprocess import Popen, PIPE
from tempfile import NamedTemporaryFile
from graphlib import TopologicalSorter

REPO = Path(__file__).resolve().parents[1]
PROJECT = REPO / "upstream/extracted/lean"
TOOLCHAIN = REPO / "toolchain/lean-4.33.1-linux"


def parse_headers(paths):
    with NamedTemporaryFile(mode="w", encoding="utf-8") as source_list:
        source_list.writelines(f"{path}\n" for path in paths)
        source_list.flush()
        command = [TOOLCHAIN / "bin/lean", "--run", REPO / "lean/ParseImports.lean", source_list.name]
        with Popen(command, stdout=PIPE, text=True) as parser:
            for line in parser.stdout:
                path, *imports = line.rstrip("\n").split("\t")
                yield Path(path), imports
            if parser.wait():
                raise RuntimeError("Lean's import parser failed")


def main():
    source = PROJECT / "src"
    imports = {
        ".".join(path.relative_to(source).with_suffix("").parts): dependencies
        for path, dependencies in parse_headers(source.rglob("*.lean"))
    }
    local = {}
    external = set()
    pending = ["Main"]
    while pending:
        name = pending.pop()
        if name in local or name in external:
            continue
        if name not in imports:
            external.add(name)
            continue
        local[name] = [dependency for dependency in imports[name] if dependency in imports]
        pending.extend(imports[name])

    depth = {}
    for name in TopologicalSorter(local).static_order():
        depth[name] = 1 + max((depth[dependency] for dependency in local[name]), default=0)

    print(f"Headers parsed by Lean: {len(imports)}")
    print(f"Local modules reachable from Main: {len(local)}")
    print(f"External module names in the closure, including implicit Init: {len(external)}")
    print("Local import graph is acyclic.")
    print(f"Longest local import chain ending at Main: {depth['Main']} modules.")


if __name__ == "__main__":
    main()
