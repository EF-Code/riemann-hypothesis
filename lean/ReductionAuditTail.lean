namespace ReductionAudit

theorem zetaStatementMatches : RiemannHypothesis ↔ RiemannZetaZerosOnLine :=
  Iff.rfl

theorem characterStatementMatches :
    UpperTheory.EveryCharacter ↔ DirichletLNonvanishingRightOfHalf :=
  Iff.rfl

theorem rhOfRightHalfPlane (h : DirichletLNonvanishingRightOfHalf) : RiemannHypothesis :=
  Formalism.VW.rh_of_every h

theorem grhOfRightHalfPlane (h : DirichletLNonvanishingRightOfHalf) : DirichletLZerosOnLine :=
  Claim.strip h

theorem primitiveGRHOfRightHalfPlane
    (h : DirichletLNonvanishingRightOfHalf) : PrimitiveDirichletLZerosOnLine :=
  Formalism.VW.critLine h

#print axioms zetaStatementMatches
#print axioms characterStatementMatches
#print axioms rhOfRightHalfPlane
#print axioms grhOfRightHalfPlane
#print axioms primitiveGRHOfRightHalfPlane

end ReductionAudit
