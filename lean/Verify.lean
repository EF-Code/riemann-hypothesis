import Mathlib.NumberTheory.LSeries.DirichletContinuation
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Main
import Lean.Util.CollectAxioms
import Lean.Elab.Command

open Lean

namespace Verification

theorem standardRH : _root_.RiemannHypothesis :=
  _root_.riemannHypothesis

theorem expandedRH (s : ℂ) (hzero : _root_.riemannZeta s = 0)
    (htrivial : ¬ ∃ n : ℕ, s = -2 * ((n : ℂ) + 1)) (hpole : s ≠ 1) :
    s.re = 1 / 2 :=
  standardRH s hzero htrivial hpole

theorem dirichletGRH (N : ℕ) [NeZero N] (χ : _root_.DirichletCharacter ℂ N)
    (s : ℂ) (hleft : 0 < s.re) (hright : s.re < 1)
    (hzero : _root_.DirichletCharacter.LFunction χ s = 0) :
    s.re = 1 / 2 :=
  _root_.LFunction_eq_zero_re N χ s hleft hright hzero

#print axioms standardRH
#print axioms expandedRH
#print axioms dirichletGRH

run_cmd do
  let allowed := [`propext, `Classical.choice, `Quot.sound]
  for theoremName in [``standardRH, ``expandedRH, ``dirichletGRH] do
    let axioms ← collectAxioms theoremName
    let unexpected := axioms.filter fun axiomName => !allowed.contains axiomName
    unless unexpected.isEmpty do
      throwError "{theoremName} uses unexpected axioms: {unexpected.toList}"

end Verification
