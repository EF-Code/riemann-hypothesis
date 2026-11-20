# Lean verification of Alpöge’s Riemann Hypothesis claim

**Status on 20 November 2026: proof verification pending.** The original archive passed integrity checks and the source declares the standard Mathlib proposition. The local build is in progress. The conditional RH and Dirichlet GRH reductions passed. The theorem’s axiom dependencies and fresh-kernel replay remain pending until Lean finishes building `Main`. [Alpöge’s announcement](https://alpo.ge/remark.pdf)

## Verified inputs and findings

| Check | Result |
| --- | --- |
| Original archive | All 14 parts retrieved from `alpo.ge`. The combined gzip passed integrity testing and all [extracted archive files matched byte for byte](evidence/extracted-source-match.txt). SHA-256 hashes are in [upstream.sha256](evidence/upstream.sha256). |
| Lean release | Lean 4.33.1, commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`. The downloaded Linux release matched the digest in GitHub’s release metadata. |
| Dependency revisions | All nine Git dependencies checked out at the revisions in the archive’s manifest. Mathlib is pinned to `0df444a360eaa60ab8c11dca51a86af692955474`. |
| Theorem identification | `riemannHypothesis` in module `Main`. Its source type is Mathlib’s `RiemannHypothesis`. |
| Source inventory | Lean's import parser confirmed that [the acyclic graph from `Main`](evidence/lean-import-graph.txt) reaches all 175,187 local source modules. The text scan found zero occurrences of `sorry`, `admit`, `sorryAx`, and explicit `axiom` declarations. |
| Build | The [Mathlib cache request](evidence/cache-attempt.txt) returned HTTP 403 in this workspace. Lake is compiling dependencies from source on two CPU cores. See `evidence/build-main.log` and `evidence/build-reduction-deps.log` for progress and `evidence/status.log` for stage results. |
| Conditional reduction | Lean proved the RH, Dirichlet GRH, and primitive Dirichlet GRH implications from right-half-plane nonvanishing. All five audited declarations depend only on the standard axioms, and Nanoda replayed the export successfully. [Lean output](evidence/reduction-audit.txt) · [Nanoda result](evidence/reduction-nanoda.txt) |
| Axiom and kernel checks | Pending for the unconditional RH and Dirichlet GRH claims. The [axiom guard controls](evidence/axiom-guard-smoke.txt) and [fresh-kernel control](evidence/leanchecker-prelude-smoke.txt) passed. |

The terminal declaration is in [the extracted Main.lean](upstream/extracted/lean/src/Main.lean). Mathlib’s proposition says that every zero of its analytically continued Riemann zeta function, excluding the negative even integers and the pole at 1, has real part 1/2. The archive also exposes a Dirichlet GRH claim for critical-strip zeros of all Dirichlet characters. [Mathlib’s pinned RH definition](https://github.com/leanprover-community/mathlib4/blob/0df444a360eaa60ab8c11dca51a86af692955474/Mathlib/NumberTheory/LSeries/RiemannZeta.lean#L185)

The first steps in the source are `riemannHypothesis` → `rhOfAll` → `Formalism.VW.rh_of_every allChi`. The reduction specializes the asserted right-half-plane nonvanishing for Dirichlet L-functions to the character modulo 1, then uses the zeta functional equation for the other half-plane. This records the reduction and target. The analytic argument supplying `allChi` still needs mathematical review. The [reduction review](evidence/reduction-review.md) describes the conditional argument. [MainTheorems.lean](upstream/extracted/lean/src/Supplements/Kernels/MainTheorems.lean) · [CritLine.lean](upstream/extracted/lean/src/Formalism/GammaFactorNonvanishing/CritLine.lean) · [RhOfRight.lean](upstream/extracted/lean/src/Formalism/GammaFactorNonvanishing/RhOfRight.lean)

## Reproduce on x86-64 Linux

The scripts use Git, curl, GNU tar, gzip, zstd, Python 3, and Bubblewrap. The build runs with the verified Lean distribution, no network, and a separate home directory. The original PDF, downloaded archives, dependency checkouts, and build products are stored locally and regenerated from the pinned inputs when needed.

```sh
./scripts/fetch.sh
./scripts/fetch-dependencies.py
./scripts/inspect-source.py
./scripts/check-import-graph.py
./scripts/verify.sh --check-reduction-first
```

Where the official Mathlib cache is reachable, `./scripts/isolated-lean.sh --network lake exe cache get --repo=leanprover-community/mathlib4` can prepare the dependency cache before verification.

The verification script builds the archive’s `Main` module. [Verify.lean](lean/Verify.lean) then applies the author’s declarations to an independently written zeta-zero statement and a Dirichlet critical-strip statement. It prints transitive axioms and fails on any axiom outside `propext`, `Classical.choice`, and `Quot.sound`. The last stage invokes Lean’s fresh-kernel replay on the compiled audit module and its imports. An external checker and a full mathematical review are still pending. [Lean proof validation reference](https://lean-lang.org/doc/reference/latest/ValidatingProofs/)

The SHA-256 entries for Alpöge’s files identify the bytes retrieved for this audit. The Lean archive digest was also compared with the official release metadata. [Lean 4.33.1 release](https://github.com/leanprover/lean4/releases/tag/v4.33.1)

## Conditional reduction and independent checker

The optional first stage compiles the RH and Dirichlet GRH reductions from the archive with focused Mathlib imports. It checks the original proof bodies with the Dirichlet right-half-plane nonvanishing statement as a hypothesis. The full build resumes afterwards and is needed to check the archive's proof of that hypothesis.

Comparator uses Lean 4.36.0 and Nanoda. The exporter is lean4export v4.33.0, built by Lean 4.33.1. The controls exercise theorem acceptance, a statement mismatch, and rejection of a custom axiom. Comparator checks the solution against the independently compiled challenge and permits three standard axioms. [Lean release](https://github.com/leanprover/lean4/releases/tag/v4.36.0) · [Export tool](https://github.com/leanprover/lean4export/tree/v4.33.0) · [Comparator controls](evidence/comparator-smoke.txt)

```sh
./scripts/prepare-comparator.sh
./scripts/run-comparator.sh --challenge
./scripts/run-comparator.sh --solution
```

The challenge compiled against the pinned Mathlib artifacts for `DirichletContinuation` and `RiemannZeta` and was exported on 20 November 2026. [Challenge export hash](evidence/comparator-challenge.sha256) The solution phase needs `Verify.olean` from the full verification script. A separate public audit also reported successful CI for its Mathlib-only challenge and its archive match. [Independent CI run](https://github.com/Deicyde/riemann-hypothesis/actions/runs/44794153518)
