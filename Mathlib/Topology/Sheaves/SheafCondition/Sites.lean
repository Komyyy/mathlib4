/-
Copyright (c) 2021 Justus Springer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Justus Springer
-/
import Mathlib.CategoryTheory.Sites.Spaces
import Mathlib.Topology.Sheaves.Sheaf
import Mathlib.CategoryTheory.Sites.DenseSubsite.Basic

/-!

# Coverings and sieves; from sheaves on sites and sheaves on spaces

In this file, we connect coverings in a topological space to sieves in the associated Grothendieck
topology, in preparation of connecting the sheaf condition on sites to the various sheaf conditions
on spaces.

We also specialize results about sheaves on sites to sheaves on spaces; we show that the inclusion
functor from a topological basis to `TopologicalSpace.Opens` is cover dense, that open maps
induce cover preserving functors, and that open embeddings induce continuous functors.

-/


noncomputable section

open CategoryTheory TopologicalSpace Topology

universe w v u

namespace TopCat.Presheaf

variable {X : TopCat.{w}}

/-- Given a presieve `R` on `U`, we obtain a covering family of open sets in `X`, by taking as index
type the type of dependent pairs `(V, f)`, where `f : V ⟶ U` is in `R`.
-/
def coveringOfPresieve (U : Opens X) (R : Presieve U) : (Σ V, { f : V ⟶ U // R f }) → Opens X :=
  fun f => f.1

@[simp]
theorem coveringOfPresieve_apply (U : Opens X) (R : Presieve U) (f : Σ V, { f : V ⟶ U // R f }) :
    coveringOfPresieve U R f = f.1 := rfl

namespace coveringOfPresieve

variable (U : Opens X) (R : Presieve U)

/-- If `R` is a presieve in the grothendieck topology on `Opens X`, the covering family associated
to `R` really is _covering_, i.e. the union of all open sets equals `U`.
-/
theorem iSup_eq_of_mem_grothendieck (hR : Sieve.generate R ∈ Opens.grothendieckTopology X U) :
    iSup (coveringOfPresieve U R) = U := by
  apply le_antisymm
  · refine iSup_le ?_
    intro f
    exact f.2.1.le
  intro x hxU
  rw [Opens.coe_iSup, Set.mem_iUnion]
  obtain ⟨V, iVU, ⟨W, iVW, iWU, hiWU, -⟩, hxV⟩ := hR x hxU
  exact ⟨⟨W, ⟨iWU, hiWU⟩⟩, iVW.le hxV⟩

end coveringOfPresieve

/-- Given a family of opens `U : ι → Opens X` and any open `Y : Opens X`, we obtain a presieve
on `Y` by declaring that a morphism `f : V ⟶ Y` is a member of the presieve if and only if
there exists an index `i : ι` such that `V = U i`.
-/
def presieveOfCoveringAux {ι : Type v} (U : ι → Opens X) (Y : Opens X) : Presieve Y :=
  fun V _ => ∃ i, V = U i

/-- Take `Y` to be `iSup U` and obtain a presieve over `iSup U`. -/
def presieveOfCovering {ι : Type v} (U : ι → Opens X) : Presieve (iSup U) :=
  presieveOfCoveringAux U (iSup U)

/-- Given a presieve `R` on `Y`, if we take its associated family of opens via
    `coveringOfPresieve` (which may not cover `Y` if `R` is not covering), and take
    the presieve on `Y` associated to the family of opens via `presieveOfCoveringAux`,
    then we get back the original presieve `R`. -/
@[simp]
theorem covering_presieve_eq_self {Y : Opens X} (R : Presieve Y) :
    presieveOfCoveringAux (coveringOfPresieve Y R) Y = R := by
  funext Z
  ext f
  exact ⟨fun ⟨⟨_, f', h⟩, rfl⟩ => by rwa [Subsingleton.elim f f'], fun h => ⟨⟨Z, f, h⟩, rfl⟩⟩

namespace presieveOfCovering

variable {ι : Type v} (U : ι → Opens X)

/-- The sieve generated by `presieveOfCovering U` is a member of the grothendieck topology.
-/
theorem mem_grothendieckTopology :
    Sieve.generate (presieveOfCovering U) ∈ Opens.grothendieckTopology X (iSup U) := by
  intro x hx
  obtain ⟨i, hxi⟩ := Opens.mem_iSup.mp hx
  exact ⟨U i, Opens.leSupr U i, ⟨U i, 𝟙 _, Opens.leSupr U i, ⟨i, rfl⟩, Category.id_comp _⟩, hxi⟩

/-- An index `i : ι` can be turned into a dependent pair `(V, f)`, where `V` is an open set and
`f : V ⟶ iSup U` is a member of `presieveOfCovering U f`.
-/
def homOfIndex (i : ι) : Σ V, { f : V ⟶ iSup U // presieveOfCovering U f } :=
  ⟨U i, Opens.leSupr U i, i, rfl⟩

/-- By using the axiom of choice, a dependent pair `(V, f)` where `f : V ⟶ iSup U` is a member of
`presieveOfCovering U f` can be turned into an index `i : ι`, such that `V = U i`.
-/
def indexOfHom (f : Σ V, { f : V ⟶ iSup U // presieveOfCovering U f }) : ι :=
  f.2.2.choose

theorem indexOfHom_spec (f : Σ V, { f : V ⟶ iSup U // presieveOfCovering U f }) :
    f.1 = U (indexOfHom U f) :=
  f.2.2.choose_spec

end presieveOfCovering

end TopCat.Presheaf

namespace TopCat.Opens

variable {X : TopCat} {ι : Type*}

theorem coverDense_iff_isBasis [Category ι] (B : ι ⥤ Opens X) :
    B.IsCoverDense (Opens.grothendieckTopology X) ↔ Opens.IsBasis (Set.range B.obj) := by
  rw [Opens.isBasis_iff_nbhd]
  constructor
  · intro hd U x hx; rcases hd.1 U x hx with ⟨V, f, ⟨i, f₁, f₂, _⟩, hV⟩
    exact ⟨B.obj i, ⟨i, rfl⟩, f₁.le hV, f₂.le⟩
  intro hb; constructor; intro U x hx; rcases hb hx with ⟨_, ⟨i, rfl⟩, hx, hi⟩
  exact ⟨B.obj i, ⟨⟨hi⟩⟩, ⟨⟨i, 𝟙 _, ⟨⟨hi⟩⟩, rfl⟩⟩, hx⟩

theorem coverDense_inducedFunctor {B : ι → Opens X} (h : Opens.IsBasis (Set.range B)) :
    (inducedFunctor B).IsCoverDense (Opens.grothendieckTopology X)  :=
  (coverDense_iff_isBasis _).2 h

end TopCat.Opens

section IsOpenEmbedding

open TopCat.Presheaf Opposite

variable {C : Type u} [Category.{v} C]
variable {X Y : TopCat.{w}} {f : X ⟶ Y} {F : Y.Presheaf C}

theorem Topology.IsOpenEmbedding.compatiblePreserving (hf : IsOpenEmbedding f) :
    CompatiblePreserving (Opens.grothendieckTopology Y) hf.isOpenMap.functor := by
  haveI : Mono f := (TopCat.mono_iff_injective f).mpr hf.injective
  apply compatiblePreservingOfDownwardsClosed
  intro U V i
  refine ⟨(Opens.map f).obj V, eqToIso <| Opens.ext <| Set.image_preimage_eq_of_subset fun x h ↦ ?_⟩
  obtain ⟨_, _, rfl⟩ := i.le h
  exact ⟨_, rfl⟩

theorem IsOpenMap.coverPreserving (hf : IsOpenMap f) :
    CoverPreserving (Opens.grothendieckTopology X) (Opens.grothendieckTopology Y) hf.functor := by
  constructor
  rintro U S hU _ ⟨x, hx, rfl⟩
  obtain ⟨V, i, hV, hxV⟩ := hU x hx
  exact ⟨_, hf.functor.map i, ⟨_, i, 𝟙 _, hV, rfl⟩, Set.mem_image_of_mem f hxV⟩


lemma Topology.IsOpenEmbedding.functor_isContinuous (h : IsOpenEmbedding f) :
    h.isOpenMap.functor.IsContinuous (Opens.grothendieckTopology X)
      (Opens.grothendieckTopology Y) := by
  apply Functor.isContinuous_of_coverPreserving
  · exact h.compatiblePreserving
  · exact h.isOpenMap.coverPreserving

theorem TopCat.Presheaf.isSheaf_of_isOpenEmbedding (h : IsOpenEmbedding f) (hF : F.IsSheaf) :
    IsSheaf (h.isOpenMap.functor.op ⋙ F) := by
  have := h.functor_isContinuous
  exact Functor.op_comp_isSheaf _ _ _ ⟨_, hF⟩

variable (f)

instance : RepresentablyFlat (Opens.map f) := by
  constructor
  intro U
  refine @IsCofiltered.mk _ _ ?_ ?_
  · constructor
    · intro V W
      exact ⟨⟨⟨PUnit.unit⟩, V.right ⊓ W.right, homOfLE <| le_inf V.hom.le W.hom.le⟩,
        StructuredArrow.homMk (homOfLE inf_le_left),
        StructuredArrow.homMk (homOfLE inf_le_right), trivial⟩
    · exact fun _ _ _ _ ↦ ⟨_, 𝟙 _, by simp [eq_iff_true_of_subsingleton]⟩
  · exact ⟨StructuredArrow.mk <| show U ⟶ (Opens.map f).obj ⊤ from homOfLE le_top⟩

theorem compatiblePreserving_opens_map :
    CompatiblePreserving (Opens.grothendieckTopology X) (Opens.map f) :=
  compatiblePreservingOfFlat _ _

theorem coverPreserving_opens_map : CoverPreserving (Opens.grothendieckTopology Y)
    (Opens.grothendieckTopology X) (Opens.map f) := by
  constructor
  intro U S hS x hx
  obtain ⟨V, i, hi, hxV⟩ := hS (f x) hx
  exact ⟨_, (Opens.map f).map i, ⟨_, _, 𝟙 _, hi, Subsingleton.elim _ _⟩, hxV⟩

instance : (Opens.map f).IsContinuous (Opens.grothendieckTopology Y)
    (Opens.grothendieckTopology X) := by
  apply Functor.isContinuous_of_coverPreserving
  · exact compatiblePreserving_opens_map f
  · exact coverPreserving_opens_map f

end IsOpenEmbedding

namespace TopCat.Sheaf

open TopCat Opposite

variable {C : Type u} [Category.{v} C]
variable {X : TopCat.{w}} {ι : Type*} {B : ι → Opens X}
variable (F : X.Presheaf C) (F' : Sheaf C X)

/-- The empty component of a sheaf is terminal. -/
def isTerminalOfEmpty (F : Sheaf C X) : Limits.IsTerminal (F.val.obj (op ⊥)) :=
  F.isTerminalOfBotCover ⊥ (fun _ h => h.elim)

/-- A variant of `isTerminalOfEmpty` that is easier to `apply`. -/
def isTerminalOfEqEmpty (F : X.Sheaf C) {U : Opens X} (h : U = ⊥) :
    Limits.IsTerminal (F.val.obj (op U)) := by
  convert F.isTerminalOfEmpty

/-- If a family `B` of open sets forms a basis of the topology on `X`, and if `F'`
    is a sheaf on `X`, then a homomorphism between a presheaf `F` on `X` and `F'`
    is equivalent to a homomorphism between their restrictions to the indexing type
    `ι` of `B`, with the induced category structure on `ι`. -/
def restrictHomEquivHom (h : Opens.IsBasis (Set.range B)) :
    ((inducedFunctor B).op ⋙ F ⟶ (inducedFunctor B).op ⋙ F'.1) ≃ (F ⟶ F'.1) :=
  @Functor.IsCoverDense.restrictHomEquivHom _ _ _ _ _ _ _ _
    (Opens.coverDense_inducedFunctor h) _ F F'

@[simp]
theorem extend_hom_app (h : Opens.IsBasis (Set.range B))
    (α : (inducedFunctor B).op ⋙ F ⟶ (inducedFunctor B).op ⋙ F'.1) (i : ι) :
    (restrictHomEquivHom F F' h α).app (op (B i)) = α.app (op i) := by
  nth_rw 2 [← (restrictHomEquivHom F F' h).left_inv α]
  rfl

theorem hom_ext (h : Opens.IsBasis (Set.range B))
    {α β : F ⟶ F'.1} (he : ∀ i, α.app (op (B i)) = β.app (op (B i))) : α = β := by
  apply (restrictHomEquivHom F F' h).symm.injective
  ext i
  exact he i.unop

end TopCat.Sheaf
