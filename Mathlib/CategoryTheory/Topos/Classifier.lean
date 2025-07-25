/-
Copyright (c) 2024 Charlie Conneen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Charlie Conneen, Pablo Donato, Klaus Gy
-/
import Mathlib.CategoryTheory.Limits.Shapes.RegularMono
import Mathlib.CategoryTheory.Limits.Shapes.Pullback.CommSq
import Mathlib.CategoryTheory.Functor.ReflectsIso.Balanced
import Mathlib.CategoryTheory.Subobject.Presheaf

/-!

# Subobject Classifier

We define what it means for a morphism in a category to be a subobject classifier as
`CategoryTheory.HasClassifier`.

c.f. the following Lean 3 code, where similar work was done:
https://github.com/b-mehta/topos/blob/master/src/subobject_classifier.lean

## Main definitions

Let `C` refer to a category with a terminal object.

* `CategoryTheory.Classifier C` is the data of a subobject classifier in `C`.

* `CategoryTheory.HasClassifier C` says that there is at least one subobject classifier.
  `Ω C` denotes a choice of subobject classifier.

## Main results

* It is a theorem that the truth morphism `⊤_ C ⟶ Ω C` is a (split, and therefore regular)
  monomorphism, simply because its source is the terminal object.

* An instance of `IsRegularMonoCategory C` is exhibited for any category with a subobject
  classifier.

* `CategoryTheory.Classifier.representableBy`: any subobject classifier `Ω` in `C` represents the
  subobjects functor `CategoryTheory.Subobject.presheaf C`.

* `CategoryTheory.Classifier.SubobjectRepresentableBy.classifier`: any representation `Ω` of
  `CategoryTheory.Subobject.presheaf C` is a subobject classifier in `C`.

* `CategoryTheory.hasClassifier_isRepresentable_iff`: from the two above mappings, we get that a
  category `C` has a subobject classifier if and only if the subobjects presheaf
  `CategoryTheory.Subobject.presheaf C` is representable (Proposition 1 in Section I.3 of [MM92]).

## References

* [S. MacLane and I. Moerdijk, *Sheaves in Geometry and Logic*][MM92]

-/

universe u v u₀ v₀

namespace CategoryTheory

open Category Limits Functor IsPullback

variable (C : Type u) [Category.{v} C]

/-- A monomorphism `truth : Ω₀ ⟶ Ω` is a subobject classifier if, for every monomorphism
`m : U ⟶ X` in `C`, there is a unique map `χ : X ⟶ Ω` such that for some (necessarily unique)
`χ₀ : U ⟶ Ω₀` the following square is a pullback square:
```
      U ---------m----------> X
      |                       |
    χ₀ U                     χ m
      |                       |
      v                       v
      Ω₀ ------truth--------> Ω
```
An equivalent formulation replaces `Ω₀` with the terminal object.
-/
structure Classifier where
  /-- The domain of the truth morphism -/
  Ω₀ : C
  /-- The codomain of the truth morphism -/
  Ω : C
  /-- The truth morphism of the subobject classifier -/
  truth : Ω₀ ⟶ Ω
  /-- The truth morphism is a monomorphism -/
  mono_truth : Mono truth
  /-- The top arrow in the pullback square -/
  χ₀ (U : C) : U ⟶ Ω₀
  /-- For any monomorphism `U ⟶ X`, there is an associated characteristic map `X ⟶ Ω`. -/
  χ {U X : C} (m : U ⟶ X) [Mono m] : X ⟶ Ω
  /-- `χ₀ U` and `χ m` form the appropriate pullback square. -/
  isPullback {U X : C} (m : U ⟶ X) [Mono m] : IsPullback m (χ₀ U) (χ m) truth
  /-- `χ m` is the only map `X ⟶ Ω` which forms the appropriate pullback square for any `χ₀'`. -/
  uniq {U X : C} (m : U ⟶ X) [Mono m] {χ₀' : U ⟶ Ω₀} {χ' : X ⟶ Ω}
    (hχ' : IsPullback m χ₀' χ' truth) : χ' = χ m

variable {C}

namespace Classifier

attribute [instance] mono_truth

/-- More explicit constructor in case `Ω₀` is already known to be a terminal object. -/
@[simps]
def mkOfTerminalΩ₀
    (Ω₀ : C)
    (t : IsTerminal Ω₀)
    (Ω : C)
    (truth : Ω₀ ⟶ Ω)
    (χ : ∀ {U X : C} (m : U ⟶ X) [Mono m], X ⟶ Ω)
    (isPullback : ∀ {U X : C} (m : U ⟶ X) [Mono m],
      IsPullback m (t.from U) (χ m) truth)
    (uniq : ∀ {U X : C} (m : U ⟶ X) [Mono m] (χ' : X ⟶ Ω)
      (_ : IsPullback m (t.from U) χ' truth), χ' = χ m) : Classifier C where
  Ω₀ := Ω₀
  Ω := Ω
  truth := truth
  mono_truth := t.mono_from _
  χ₀ := t.from
  χ m _ := χ m
  isPullback m _ := isPullback m
  uniq m _ χ₀' χ' hχ' := uniq m χ' ((t.hom_ext χ₀' (t.from _)) ▸ hχ')

instance {c : Classifier C} : ∀ Y : C, Unique (Y ⟶ c.Ω₀) := fun Y =>
  { default := c.χ₀ Y,
    uniq f :=
      have : f ≫ c.truth = c.χ₀ Y ≫ c.truth :=
        by calc
          _ = c.χ (𝟙 Y) := c.uniq (𝟙 Y) (of_horiz_isIso_mono { })
          _ = c.χ₀ Y ≫ c.truth := by simp [← (c.isPullback (𝟙 Y)).w]
      Mono.right_cancellation _ _ this }

/-- Given `c : Classifier C`, `c.Ω₀` is a terminal object.
Prefer `c.χ₀` over `c.isTerminalΩ₀.from`. -/
def isTerminalΩ₀ {c : Classifier C} : IsTerminal c.Ω₀ := IsTerminal.ofUnique c.Ω₀

@[simp]
lemma isTerminalFrom_eq_χ₀ (c : Classifier C) : c.isTerminalΩ₀.from = c.χ₀ := rfl

end Classifier

/-- A category `C` has a subobject classifier if there is at least one subobject classifier. -/
class HasClassifier (C : Type u) [Category.{v} C] : Prop where
  /-- There is some classifier. -/
  exists_classifier : Nonempty (Classifier C)

namespace HasClassifier

variable (C) [HasClassifier C]

noncomputable section

/-- Notation for the `Ω₀` in an arbitrary choice of a subobject classifier -/
abbrev Ω₀ : C := HasClassifier.exists_classifier.some.Ω₀
/-- Notation for the `Ω` in an arbitrary choice of a subobject classifier -/
abbrev Ω : C := HasClassifier.exists_classifier.some.Ω

/-- Notation for the "truth arrow" in an arbitrary choice of a subobject classifier -/
abbrev truth : Ω₀ C ⟶ Ω C := HasClassifier.exists_classifier.some.truth

variable {C} {U X : C} (m : U ⟶ X) [Mono m]

/-- returns the characteristic morphism of the subobject `(m : U ⟶ X) [Mono m]` -/
def χ : X ⟶ Ω C :=
  HasClassifier.exists_classifier.some.χ m

/-- The diagram
```
      U ---------m----------> X
      |                       |
    χ₀ U                     χ m
      |                       |
      v                       v
      Ω₀ ------truth--------> Ω
```
is a pullback square.
-/
lemma isPullback_χ : IsPullback m (Classifier.χ₀ _ U) (χ m) (truth C) :=
  Classifier.isPullback _ m

/-- The diagram
```
      U ---------m----------> X
      |                       |
    χ₀ U                     χ m
      |                       |
      v                       v
      Ω₀ ------truth--------> Ω
```
commutes.
-/
@[reassoc]
lemma comm : m ≫ χ m = Classifier.χ₀ _ U ≫ truth C := (isPullback_χ m).w

/-- `χ m` is the only map for which the associated square
is a pullback square.
-/
lemma unique (χ' : X ⟶ Ω C) (hχ' : IsPullback m (Classifier.χ₀ _ U) χ' (truth C)) : χ' = χ m :=
  Classifier.uniq _ m hχ'

instance truthIsSplitMono : IsSplitMono (truth C) :=
  Classifier.isTerminalΩ₀.isSplitMono_from _

/-- `truth C` is a regular monomorphism (because it is split). -/
noncomputable instance truthIsRegularMono : RegularMono (truth C) :=
  RegularMono.ofIsSplitMono (truth C)

/-- The following diagram
```
      U ---------m----------> X
      |                       |
    χ₀ U                     χ m
      |                       |
      v                       v
      Ω₀ ------truth--------> Ω
```
being a pullback for any monic `m` means that every monomorphism
in `C` is the pullback of a regular monomorphism; since regularity
is stable under base change, every monomorphism is regular.
Hence, `C` is a regular mono category.
It also follows that `C` is a balanced category.
-/
instance isRegularMonoCategory : IsRegularMonoCategory C where
  regularMonoOfMono :=
    fun m => ⟨regularOfIsPullbackFstOfRegular (isPullback_χ m).w (isPullback_χ m).isLimit⟩

/-- If the source of a faithful functor has a subobject classifier, the functor reflects
  isomorphisms. This holds for any balanced category.
-/
instance reflectsIsomorphisms (D : Type u₀) [Category.{v₀} D] (F : C ⥤ D) [Functor.Faithful F] :
    Functor.ReflectsIsomorphisms F :=
  reflectsIsomorphisms_of_reflectsMonomorphisms_of_reflectsEpimorphisms F

/-- If the source of a faithful functor is the opposite category of one with a subobject classifier,
  the same holds -- the functor reflects isomorphisms.
-/
instance reflectsIsomorphismsOp (D : Type u₀) [Category.{v₀} D] (F : Cᵒᵖ ⥤ D)
    [Functor.Faithful F] :
    Functor.ReflectsIsomorphisms F :=
  reflectsIsomorphisms_of_reflectsMonomorphisms_of_reflectsEpimorphisms F

end
end HasClassifier

/-! ### The representability theorem of subobject classifiers -/

section Representability

namespace Classifier

open Subobject

/-! #### From classifiers to representations -/

section RepresentableBy

variable {C : Type u} [Category.{v} C] [HasPullbacks C] (𝒞 : Classifier C)

/-- The subobject of `𝒞.Ω` corresponding to the `truth` morphism. -/
abbrev truth_as_subobject : Subobject 𝒞.Ω :=
  Subobject.mk 𝒞.truth

lemma surjective_χ {X : C} (φ : X ⟶ 𝒞.Ω) :
    ∃ (Z : C) (i : Z ⟶ X) (_ : Mono i), φ = 𝒞.χ i :=
  ⟨Limits.pullback φ 𝒞.truth, pullback.fst _ _, inferInstance, 𝒞.uniq _ (by
    convert IsPullback.of_hasPullback φ 𝒞.truth)⟩

@[simp]
lemma pullback_χ_obj_mk_truth {Z X : C} (i : Z ⟶ X) [Mono i] :
    (Subobject.pullback (𝒞.χ i)).obj 𝒞.truth_as_subobject = .mk i :=
  Subobject.pullback_obj_mk (𝒞.isPullback i).flip

@[simp]
lemma χ_pullback_obj_mk_truth_arrow {X : C} (φ : X ⟶ 𝒞.Ω) :
    𝒞.χ ((Subobject.pullback φ).obj 𝒞.truth_as_subobject).arrow = φ := by
  obtain ⟨Z, i, _, rfl⟩ := 𝒞.surjective_χ φ
  refine (𝒞.uniq _ (?_ : IsPullback _ (𝒞.χ₀ _) _ _)).symm
  refine (IsPullback.of_hasPullback 𝒞.truth (𝒞.χ i)).flip.of_iso
    (underlyingIso _).symm (Iso.refl _) (Iso.refl _) (Iso.refl _)
    ?_ (𝒞.isTerminalΩ₀.hom_ext _ _) (by simp) (by simp)
  dsimp
  rw [Iso.eq_inv_comp, comp_id, underlyingIso_hom_comp_eq_mk]
  rfl

/-- Any subobject classifier `Ω` represents the subobjects functor `Subobject.presheaf`. -/
noncomputable def representableBy :
    (Subobject.presheaf C).RepresentableBy 𝒞.Ω where
  homEquiv := {
    toFun φ := (Subobject.pullback φ).obj 𝒞.truth_as_subobject
    invFun x := 𝒞.χ x.arrow
    left_inv φ := by simp
    right_inv x := by simp
  }
  homEquiv_comp _ _ := by simp [pullback_comp]

end RepresentableBy

/-! #### From representations to classifiers -/

section FromRepresentation

variable {C : Type u} [Category.{v} C] [HasPullbacks C] (Ω : C)

/-- Abbreviation to enable dot notation on the hypothesis `h` stating that the subobjects presheaf
    is representable by some object `Ω`. -/
abbrev SubobjectRepresentableBy := (Subobject.presheaf C).RepresentableBy Ω

variable {Ω} (h : SubobjectRepresentableBy Ω)

namespace SubobjectRepresentableBy

/-- `h.Ω₀` is the subobject of `Ω` which corresponds to the identity `𝟙 Ω`,
    given `h : SubobjectRepresentableBy Ω`. -/
def Ω₀ : Subobject Ω := h.homEquiv (𝟙 Ω)

/-- `h.homEquiv` acts like an "object comprehension" operator: it maps any characteristic map
    `f : X ⟶ Ω` to the associated subobject of `X`, obtained by pulling back `h.Ω₀` along `f`. -/
lemma homEquiv_eq {X : C} (f : X ⟶ Ω) :
    h.homEquiv f = (Subobject.pullback f).obj h.Ω₀ := by
  simpa using h.homEquiv_comp f (𝟙 _)

/-- For any subobject `x`, the pullback of `h.Ω₀` along the characteristic map of `x`
    given by `h.homEquiv` is `x` itself. -/
lemma pullback_homEquiv_symm_obj_Ω₀ {X : C} (x : Subobject X) :
    (Subobject.pullback (h.homEquiv.symm x)).obj h.Ω₀ = x := by
  rw [← homEquiv_eq, Equiv.apply_symm_apply]

section

variable {U X : C} (m : U ⟶ X) [Mono m]

/-- `h.χ m` is the characteristic map of monomorphism `m` given by the bijection `h.homEquiv`. -/
def χ : X ⟶ Ω := h.homEquiv.symm (Subobject.mk m)

/-- `h.iso m` is the isomorphism between `m` and the pullback of `Ω₀`
    along the characteristic map of `m`. -/
noncomputable def iso : MonoOver.mk' m ≅
    Subobject.representative.obj ((Subobject.pullback (h.χ m)).obj h.Ω₀) :=
  (Subobject.representativeIso (.mk' m)).symm ≪≫ Subobject.representative.mapIso
    (eqToIso (h.pullback_homEquiv_symm_obj_Ω₀ (.mk m)).symm)

/-- `h.π m` is the first projection in the following pullback square:

    ```
    U --h.π m--> (Ω₀ : C)
    |                |
    m             Ω₀.arrow
    |                |
    v                v
    X -----h.χ m---> Ω
    ```
-/
noncomputable def π : U ⟶ Subobject.underlying.obj h.Ω₀ :=
  (h.iso m).hom.left ≫ Subobject.pullbackπ (h.χ m) h.Ω₀

@[reassoc (attr := simp)]
lemma iso_inv_left_π :
    (h.iso m).inv.left ≫ h.π m = Subobject.pullbackπ (h.χ m) h.Ω₀ := by
  dsimp only [π]
  rw [← Over.comp_left_assoc]
  convert Category.id_comp _ using 2
  exact (MonoOver.forget _ ⋙ Over.forget _ ).congr_map (h.iso m).inv_hom_id

@[reassoc (attr := simp)]
lemma iso_inv_left_comp :
    (h.iso m).inv.left ≫ m =
      ((Subobject.pullback (h.χ m)).obj h.Ω₀).arrow :=
  MonoOver.w (h.iso m).inv

lemma isPullback {U X : C} (m : U ⟶ X) [Mono m] :
    IsPullback m (h.π m) (h.χ m) h.Ω₀.arrow := by
  fapply (Subobject.isPullback (h.χ m) h.Ω₀).flip.of_iso
    (((MonoOver.forget _ ⋙ Over.forget _).mapIso (h.iso m)).symm) (Iso.refl _)
    (Iso.refl _) (Iso.refl _)
  all_goals simp [MonoOver.forget]

variable {m}
lemma uniq {χ' : X ⟶ Ω} {π : U ⟶ h.Ω₀}
    (sq : IsPullback m π χ' h.Ω₀.arrow) : χ' = h.χ m := by
  apply h.homEquiv.injective
  simp only [χ, Equiv.apply_symm_apply, homEquiv_eq]
  simpa using Subobject.pullback_obj_mk sq.flip

end

/-- The main non-trivial result: `h.Ω₀` is actually a terminal object. -/
noncomputable def isTerminalΩ₀ : IsTerminal (h.Ω₀ : C) :=
  IsTerminal.ofUniqueHom (fun X ↦ h.π (𝟙 X)) (fun X π' ↦ by
    have : IsPullback (𝟙 X) π' (π' ≫ h.Ω₀.arrow) h.Ω₀.arrow :=
      { isLimit' := ⟨PullbackCone.IsLimit.mk _ (fun s ↦ s.fst) (by simp)
          (fun s ↦ by rw [← cancel_mono h.Ω₀.arrow, ← s.condition, Category.assoc])
          (fun s m hm _ ↦ by simpa using hm) ⟩ }
    rw [← cancel_mono h.Ω₀.arrow, h.uniq this,
      ← (h.isPullback (𝟙 X)).w, Category.id_comp])

/-- The unique map to the terminal object. -/
noncomputable def χ₀ (U : C) : U ⟶ h.Ω₀ := h.isTerminalΩ₀.from U

include h in
lemma hasTerminal : HasTerminal C := h.isTerminalΩ₀.hasTerminal

variable [HasTerminal C]

/-- `h.isoΩ₀` is the unique isomorphism from `h.Ω₀` to the canonical terminal object `⊤_ C`. -/
noncomputable def isoΩ₀ : (h.Ω₀ : C) ≅ ⊤_ C :=
  h.isTerminalΩ₀.conePointUniqueUpToIso (limit.isLimit _)

/-- Any representation `Ω` of `Subobject.presheaf C` gives a subobject classifier with truth values
    object `Ω`. -/
noncomputable def classifier : Classifier C where
  Ω₀ := ⊤_ C
  Ω := Ω
  truth := h.isoΩ₀.inv ≫ h.Ω₀.arrow
  mono_truth := terminalIsTerminal.mono_from _
  χ₀ := terminalIsTerminal.from
  χ m _ := h.χ m
  isPullback m _ :=
    (h.isPullback m).of_iso (Iso.refl _) (Iso.refl _) h.isoΩ₀ (Iso.refl _)
      (by simp) (Subsingleton.elim _ _) (by simp) (by simp)
  uniq {U X} m _ χ₀ χ' sq := by
    have : IsPullback m (h.χ₀ U) χ' h.Ω₀.arrow :=
      sq.of_iso (Iso.refl _) (Iso.refl _) (h.isoΩ₀.symm) (Iso.refl _)
        (by simp) (h.isTerminalΩ₀.hom_ext _ _) (by simp) (by simp)
    exact h.uniq this

end SubobjectRepresentableBy
end FromRepresentation
end Classifier

variable [HasTerminal C]

/-- A category has a subobject classifier if and only if the subobjects functor is representable. -/
theorem isRepresentable_hasClassifier_iff [HasPullbacks C] :
    HasClassifier C ↔ (Subobject.presheaf C).IsRepresentable := by
  constructor <;> intro h
  · obtain ⟨⟨𝒞⟩⟩ := h
    apply RepresentableBy.isRepresentable
    exact 𝒞.representableBy
  · obtain ⟨Ω, ⟨h⟩⟩ := h
    constructor; constructor
    exact Classifier.SubobjectRepresentableBy.classifier h

end Representability
end CategoryTheory
