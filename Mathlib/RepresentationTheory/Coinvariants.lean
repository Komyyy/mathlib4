/-
Copyright (c) 2025 Amelia Livingston. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Amelia Livingston
-/
import Mathlib.Algebra.Homology.ShortComplex.ModuleCat
import Mathlib.RepresentationTheory.Rep

/-!
# Coinvariants of a group representation

Given a commutative ring `k` and a monoid `G`, this file introduces the coinvariants of a
`k`-linear `G`-representation `(V, ρ)`.

We first define `Representation.Coinvariants.ker`, the submodule of `V` generated by elements
of the form `ρ g x - x` for `x : V`, `g : G`. Then the coinvariants of `(V, ρ)` are the quotient of
`V` by this submodule. We show that the functor sending a representation to its coinvariants is
left adjoint to the functor equipping a module with the trivial representation.

## Main definitions

* `Representation.Coinvariants ρ`: the coinvariants of a representation `ρ`.
* `Representation.coinvariantsFinsuppLEquiv ρ α`: given a type `α`, this is the `k`-linear
  equivalence between `(α →₀ V)_G` and `α →₀ V_G`.
* `Representation.coinvariantsTprodLeftRegularLEquiv ρ`: the `k`-linear equivalence between
  `(V ⊗ k[G])_G` and `V` sending `⟦v ⊗ single g r⟧ ↦ r • ρ(g⁻¹)(v)`.
* `Rep.coinvariantsAdjunction k G`: the adjunction between the functor sending a representation to
  its coinvariants and the functor equipping a module with the trivial representation.
* `Rep.coinvariantsTensor k G`: the functor sending representations `A, B` to `(A ⊗[k] B)_G`. This
  is naturally isomorphic to the functor sending `A, B` to `A ⊗[k[G]] B`, where we give `A` the
  `k[G]ᵐᵒᵖ`-module structure defined by `g • a := A.ρ g⁻¹ a`.
* `Rep.coinvariantsTensorFreeLEquiv A α`: given a representation `A` and a type `α`, this is the
  `k`-linear equivalence between `(A ⊗ (α →₀ k[G]))_G` and `α →₀ A` sending
  `⟦a ⊗ single x (single g r)⟧ ↦ single x (r • ρ(g⁻¹)(a))`. This is useful for group homology.

-/

universe u v

namespace Representation

variable {k G V W X : Type*} [CommRing k] [Monoid G] [AddCommGroup V] [Module k V]
  [AddCommGroup W] [Module k W] [AddCommGroup X] [Module k X]
  (ρ : Representation k G V) (τ : Representation k G W) (υ : Representation k G X)

/-- The submodule of a representation generated by elements of the form `ρ g x - x`. -/
def Coinvariants.ker : Submodule k V :=
  Submodule.span k (Set.range fun (gv : G × V) => ρ gv.1 gv.2 - gv.2)

/-- The coinvariants of a representation, `V ⧸ ⟨{ρ g x - x | g ∈ G, x ∈ V}⟩`. -/
def Coinvariants := V ⧸ Coinvariants.ker ρ

namespace Coinvariants

instance : AddCommGroup (Coinvariants ρ) := inferInstanceAs <| AddCommGroup (_ ⧸ _)
instance : Module k (Coinvariants ρ) := inferInstanceAs <| Module k (_ ⧸ _)

variable {ρ}

lemma sub_mem_ker (g : G) (x : V) : ρ g x - x ∈ Coinvariants.ker ρ :=
  Submodule.subset_span <| Set.mem_range_self (g, x)

lemma mem_ker_of_eq (g : G) (x : V) (a : V) (h : ρ g x - x = a) : a ∈ ker ρ :=
  Submodule.subset_span ⟨(g, x), h⟩

variable (ρ)

/-- The quotient map from a representation to its coinvariants as a linear map. -/
def mk : V →ₗ[k] Coinvariants ρ := Submodule.mkQ (ker ρ)

theorem mk_eq_iff {x y : V} :
    mk ρ x = mk ρ y ↔ x - y ∈ Coinvariants.ker ρ :=
  Submodule.Quotient.eq _

theorem mk_eq_zero {x : V} :
    mk ρ x = 0 ↔ x ∈ Coinvariants.ker ρ :=
  Submodule.Quotient.mk_eq_zero _

theorem mk_surjective : Function.Surjective (mk ρ) :=
  Submodule.Quotient.mk_surjective _

@[simp]
lemma mk_self_apply (g : G) (x : V) :
    mk ρ (ρ g x) = mk ρ x :=
  (mk_eq_iff _).2 <| mem_ker_of_eq g x _ rfl

variable {ρ} in
@[elab_as_elim]
theorem induction_on {motive : Coinvariants ρ → Prop} (x : Coinvariants ρ)
    (h : ∀ v : V, motive (mk ρ v)) :
    motive x :=
  Submodule.Quotient.induction_on _ x h

/-- A `G`-invariant linear map induces a linear map out of the coinvariants of a
`G`-representation. -/
def lift (f : V →ₗ[k] W) (h : ∀ (x : G), f ∘ₗ ρ x = f) :
    ρ.Coinvariants →ₗ[k] W :=
  Submodule.liftQ _ f <| Submodule.span_le.2 fun x ⟨⟨g, y⟩, hy⟩ => by
    simpa only [← hy, SetLike.mem_coe, LinearMap.mem_ker, map_sub, sub_eq_zero, LinearMap.coe_comp,
      Function.comp_apply] using LinearMap.ext_iff.1 (h g) y

@[simp]
theorem lift_comp_mk (f : V →ₗ[k] W) (h : ∀ (x : G), f ∘ₗ ρ x = f) :
    lift ρ f h ∘ₗ mk ρ = f := rfl

@[simp]
theorem lift_mk (f : V →ₗ[k] W) (h : ∀ (x : G), f ∘ₗ ρ x = f) (x : V) :
    lift ρ f h (mk _ x) = f x := rfl

variable {ρ} in
@[ext high]
lemma hom_ext {f g : Coinvariants ρ →ₗ[k] W} (H : f ∘ₗ mk ρ = g ∘ₗ mk ρ) : f = g :=
  Submodule.linearMap_qext _ H

/-- Given `G`-representations on `k`-modules `V, W`, a linear map `V →ₗ[k] W` commuting with
the representations induces a `k`-linear map between the coinvariants. -/
noncomputable def map (f : V →ₗ[k] W) (hf : ∀ g, f ∘ₗ ρ g = τ g ∘ₗ f) :
    Coinvariants ρ →ₗ[k] Coinvariants τ :=
  lift _ (mk _ ∘ₗ f) fun g => LinearMap.ext fun x => (mk_eq_iff _).2 <|
    mem_ker_of_eq g (f x) _ <| by simpa using congr($((hf g).symm) x)

variable {ρ τ}

@[simp]
lemma map_comp_mk (f : V →ₗ[k] W) (hf : ∀ g, f ∘ₗ ρ g = τ g ∘ₗ f) :
    map ρ τ f hf ∘ₗ mk ρ = mk τ ∘ₗ f := rfl

@[simp]
lemma map_mk (f : V →ₗ[k] W) (hf : ∀ g, f ∘ₗ ρ g = τ g ∘ₗ f) (x : V) :
    map ρ τ f hf (mk _ x) = mk _ (f x) := rfl

@[simp]
lemma map_id (ρ : Representation k G V) :
    map ρ ρ LinearMap.id (by simp) = LinearMap.id := by
  ext; rfl

@[simp]
lemma map_comp (φ : V →ₗ[k] W) (ψ : W →ₗ[k] X)
    (H : ∀ g, φ ∘ₗ ρ g = τ g ∘ₗ φ) (h : ∀ g, ψ ∘ₗ τ g = υ g ∘ₗ ψ) :
    map τ υ ψ h ∘ₗ map ρ τ φ H = map ρ υ (ψ ∘ₗ φ) (fun g => by
      ext x; have : φ _ = _ := congr($(H g) x); have : ψ _ = _ := congr($(h g) (φ x)); simp_all) :=
  hom_ext rfl

end Coinvariants
section

open Coinvariants

variable {k G V : Type*} [CommRing k] [Group G] [AddCommGroup V] [Module k V]
variable (ρ : Representation k G V) (S : Subgroup G) [S.Normal]

lemma Coinvariants.le_comap_ker (g : G) :
    ker (ρ.comp S.subtype) ≤ (ker <| ρ.comp S.subtype).comap (ρ g) :=
  Submodule.span_le.2 fun _ ⟨⟨s, x⟩, hs⟩ => by
    simpa [← hs] using mem_ker_of_eq
      ⟨g * s * g⁻¹, Subgroup.Normal.conj_mem ‹_› s.1 s.2 g⟩ (ρ g x) _ <| by simp

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `ρ` restricts to a `G`-representation on
the kernel of the quotient map to the coinvariants of `ρ|_S`. -/
noncomputable abbrev toCoinvariantsKer :
    Representation k G (ker <| ρ.comp S.subtype) :=
  subrepresentation ρ (ker <| ρ.comp S.subtype) fun g => le_comap_ker ρ S g

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `ρ` induces a `G`-representation on the
coinvariants of `ρ|_S`. -/
noncomputable def toCoinvariants :
    Representation k G (Coinvariants <| ρ.comp S.subtype) :=
  quotient ρ (ker <| ρ.comp S.subtype) fun g => le_comap_ker ρ S g

@[simp]
lemma toCoinvariants_mk (g : G) (x : V) :
    toCoinvariants ρ S g (Coinvariants.mk _ x) = Coinvariants.mk _ (ρ g x) := rfl

instance : IsTrivial ((toCoinvariants ρ S).comp S.subtype) where
  out g := by
    ext x
    exact (Coinvariants.mk_eq_iff _).2 <| mem_ker_of_eq g x _ rfl

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `ρ` induces a `G ⧸ S`-representation on
the coinvariants of `ρ|_S`. -/
noncomputable abbrev quotientToCoinvariants :
    Representation k (G ⧸ S) (Coinvariants (ρ.comp S.subtype)) :=
  ofQuotient (toCoinvariants ρ S) S

end


section Finsupp

open Finsupp Coinvariants

variable {k G V : Type*} [CommRing k] [Group G] [AddCommGroup V] [Module k V]
  (ρ : Representation k G V) (α : Type*)

/-- Given a `G`-representation `(V, ρ)` and a type `α`, this is the map `(α →₀ V)_G →ₗ (α →₀ V_G)`
sending `⟦single a v⟧ ↦ single a ⟦v⟧`. -/
noncomputable def coinvariantsToFinsupp :
    Coinvariants (ρ.finsupp α) →ₗ[k] α →₀ Coinvariants ρ :=
  Coinvariants.lift _ (mapRange.linearMap (Coinvariants.mk _)) <| fun _ => by ext; simp

variable {ρ α}

@[simp]
lemma coinvariantsToFinsupp_mk_single (x : α) (a : V) :
    coinvariantsToFinsupp ρ α (Coinvariants.mk _ (single x a)) =
      single x (Coinvariants.mk _ a) := by
  simp [coinvariantsToFinsupp]

variable (ρ α) in
/-- Given a `G`-representation `(V, ρ)` and a type `α`, this is the map `(α →₀ V_G) →ₗ (α →₀ V)_G`
sending `single a ⟦v⟧ ↦ ⟦single a v⟧`. -/
noncomputable def finsuppToCoinvariants :
    (α →₀ Coinvariants ρ) →ₗ[k] Coinvariants (ρ.finsupp α) :=
  lsum (R := k) k fun a => Coinvariants.lift _ (Coinvariants.mk _ ∘ₗ lsingle a) fun g =>
    LinearMap.ext fun x => (mk_eq_iff _).2 <| mem_ker_of_eq g (single a x) _ <| by simp

@[simp]
lemma finsuppToCoinvariants_single_mk (a : α) (x : V) :
    finsuppToCoinvariants ρ α (single a <| Coinvariants.mk _ x) =
      Coinvariants.mk _ (single a x) := by
  simp [finsuppToCoinvariants]

variable (ρ α) in
/-- Given a `G`-representation `(V, ρ)` and a type `α`, this is the linear equivalence
`(α →₀ V)_G ≃ₗ (α →₀ V_G)` sending `⟦single a v⟧ ↦ single a ⟦v⟧`. -/
@[simps! symm_apply]
noncomputable def coinvariantsFinsuppLEquiv :
    Coinvariants (ρ.finsupp α) ≃ₗ[k] α →₀ Coinvariants ρ :=
  LinearEquiv.ofLinear (coinvariantsToFinsupp ρ α) (finsuppToCoinvariants ρ α)
    (by ext; simp) (by ext; simp)

@[simp]
lemma coinvariantsFinsuppLEquiv_apply (x : Coinvariants (ρ.finsupp α)) :
    coinvariantsFinsuppLEquiv ρ α x = coinvariantsToFinsupp ρ α x := by rfl

end Finsupp

section TensorProduct

open TensorProduct Coinvariants Finsupp

variable {k G V W : Type*} [CommRing k] [Group G] [AddCommGroup V] [Module k V]
  [AddCommGroup W] [Module k W] (ρ : Representation k G V) (τ : Representation k G W)

-- the next two lemmas eliminate inverses

@[simp]
lemma Coinvariants.mk_inv_tmul (x : V) (y : W) (g : G) :
    Coinvariants.mk (ρ.tprod τ) (ρ g⁻¹ x ⊗ₜ[k] y) = Coinvariants.mk (ρ.tprod τ) (x ⊗ₜ[k] τ g y) :=
  (mk_eq_iff _).2 <| mem_ker_of_eq g⁻¹ (x ⊗ₜ[k] τ g y) _ <| by simp

@[simp]
lemma Coinvariants.mk_tmul_inv (x : V) (y : W) (g : G) :
    Coinvariants.mk (ρ.tprod τ) (x ⊗ₜ[k] τ g⁻¹ y) = Coinvariants.mk (ρ.tprod τ) (ρ g x ⊗ₜ[k] y) :=
  (mk_eq_iff _).2 <| mem_ker_of_eq g⁻¹ (ρ g x ⊗ₜ[k] y) _ <| by simp

/-- Given a `k`-linear `G`-representation `V, ρ`, this is the map `(V ⊗ k[G])_G →ₗ[k] V` sending
`⟦v ⊗ single g r⟧ ↦ r • ρ(g⁻¹)(v)`. -/
noncomputable def ofCoinvariantsTprodLeftRegular :
    Coinvariants (ρ.tprod (leftRegular k G)) →ₗ[k] V :=
  Coinvariants.lift _ (TensorProduct.lift (Finsupp.linearCombination _ fun g => ρ g⁻¹) ∘ₗ
    (TensorProduct.comm _ _ _).toLinearMap) fun _ => by ext; simp

@[simp]
lemma ofCoinvariantsTprodLeftRegular_mk_tmul_single (x : V) (g : G) (r : k) :
    ofCoinvariantsTprodLeftRegular ρ (Coinvariants.mk _ (x ⊗ₜ Finsupp.single g r)) = r • ρ g⁻¹ x :=
  congr($(Finsupp.linearCombination_single k (v := fun g => ρ g⁻¹) r g) x)

/-- Given a `k`-linear `G`-representation `(V, ρ)`, this is the linear equivalence
`(V ⊗ k[G])_G ≃ₗ[k] V` sending `⟦v ⊗ single g r⟧ ↦ r • ρ(g⁻¹)(v)`. -/
@[simps! symm_apply]
noncomputable def coinvariantsTprodLeftRegularLEquiv :
    Coinvariants (ρ.tprod (leftRegular k G)) ≃ₗ[k] V :=
  LinearEquiv.ofLinear (ofCoinvariantsTprodLeftRegular ρ)
    (Coinvariants.mk _ ∘ₗ (TensorProduct.mk k V (G →₀ k)).flip (single 1 1))
    (by ext; simp) (by ext; simp)

@[simp]
lemma coinvariantsTprodLeftRegularLEquiv_apply (x : (ρ.tprod (leftRegular k G)).Coinvariants) :
    coinvariantsTprodLeftRegularLEquiv ρ x = ofCoinvariantsTprodLeftRegular ρ x := by
  rfl

end TensorProduct
end Representation

namespace Rep

open CategoryTheory Representation

variable {k G : Type u} [CommRing k]

noncomputable section

variable [Group G] (A : Rep k G) (S : Subgroup G) [S.Normal]

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `A` restricts to a `G`-representation on
the kernel of the quotient map to the `S`-coinvariants `A_S`. -/
abbrev toCoinvariantsKer : Rep k G := Rep.of (A.ρ.toCoinvariantsKer S)

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `A` induces a `G`-representation on
the `S`-coinvariants `A_S`. -/
abbrev toCoinvariants : Rep k G := Rep.of (A.ρ.toCoinvariants S)

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `ρ` induces a `G ⧸ S`-representation on
the coinvariants of `ρ|_S`. -/
abbrev quotientToCoinvariants : Rep k (G ⧸ S) := ofQuotient (toCoinvariants A S) S

/-- Given a normal subgroup `S ≤ G`, a `G`-representation `A` induces a short exact sequence of
`G`-representations `0 ⟶ Ker(mk) ⟶ A ⟶ A_S ⟶ 0` where `mk` is the quotient map to the
`S`-coinvariants `A_S`. -/
@[simps X₁ X₂ X₃ f g]
def coinvariantsShortComplex : ShortComplex (Rep k G) where
  X₁ := toCoinvariantsKer A S
  X₂ := A
  X₃ := toCoinvariants A S
  f := subtype ..
  g := mkQ ..
  zero := by ext x; exact (Submodule.Quotient.mk_eq_zero _).2 x.2

lemma coinvariantsShortComplex_shortExact : (coinvariantsShortComplex A S).ShortExact where
  exact := (forget₂ _ (ModuleCat k)).reflects_exact_of_faithful _ <|
    (ShortComplex.moduleCat_exact_iff _).2
      fun x hx => ⟨(⟨x, (Submodule.Quotient.mk_eq_zero _).1 hx⟩ :
      Representation.Coinvariants.ker <| A.ρ.comp S.subtype), rfl⟩
  mono_f := (Rep.mono_iff_injective _).2 fun _ _ h => Subtype.ext h
  epi_g := (Rep.epi_iff_surjective _).2 <| Submodule.mkQ_surjective _

end

variable (k G) [Monoid G] (A B : Rep k G)

/-- The functor sending a representation to its coinvariants. -/
@[simps! obj_carrier map_hom]
noncomputable def coinvariantsFunctor : Rep k G ⥤ ModuleCat k where
  obj A := ModuleCat.of k A.ρ.Coinvariants
  map f := ModuleCat.ofHom (Representation.Coinvariants.map _ _ f.hom.hom
    fun g => ModuleCat.hom_ext_iff.1 <| f.comm g)
  map_id _ := by simp
  map_comp _ _ := by ext; simp

/-- The quotient map from a representation to its coinvariants induces a natural transformation
from the forgetful functor `Rep k G ⥤ ModuleCat k` to the coinvariants functor. -/
@[simps! app_hom]
noncomputable def coinvariantsMk : Action.forget (ModuleCat k) G ⟶ coinvariantsFunctor k G where
  app (X : Rep k G) := ModuleCat.ofHom <| Representation.Coinvariants.mk X.ρ

instance (X : Rep k G) : Epi ((coinvariantsMk k G).app X) :=
  (ModuleCat.epi_iff_surjective _).2 <| Representation.Coinvariants.mk_surjective X.ρ

variable {k G A B}

@[ext]
lemma coinvariantsFunctor_hom_ext {M : ModuleCat k} {f g : (coinvariantsFunctor k G).obj A ⟶ M}
    (hfg : (coinvariantsMk k G).app A ≫ f = (coinvariantsMk k G).app A ≫ g) :
    f = g := (cancel_epi _).1 hfg

/-- The linear map underlying a `G`-representation morphism `A ⟶ B`, where `B` has the trivial
representation, factors through `A_G`. -/
noncomputable abbrev desc [B.ρ.IsTrivial] (f : A ⟶ B) :
    (coinvariantsFunctor k G).obj A ⟶ B.V :=
  ModuleCat.ofHom <| Representation.Coinvariants.lift _ f.hom.hom fun _ => by
    ext
    have := hom_comm_apply f
    simp_all

variable (k G)

instance : (coinvariantsFunctor k G).Additive where
instance : (coinvariantsFunctor k G).Linear k where

/-- The adjunction between the functor sending a representation to its coinvariants and the functor
equipping a module with the trivial representation. -/
@[simps]
noncomputable def coinvariantsAdjunction : coinvariantsFunctor k G ⊣ trivialFunctor k G where
  unit := { app X := {
    hom := (coinvariantsMk k G).app X
    comm _ := by ext; simp [ModuleCat.endRingEquiv, trivialFunctor] }}
  counit := { app X := desc (B := trivial k G X) (𝟙 _) }

@[simp]
theorem coinvariantsAdjunction_homEquiv_apply_hom {X : Rep k G} {Y : ModuleCat k}
    (f : (coinvariantsFunctor k G).obj X ⟶ Y) :
    ((coinvariantsAdjunction k G).homEquiv X Y f).hom = (coinvariantsMk k G).app X ≫ f := by
  rfl

@[simp]
theorem coinvariantsAdjunction_homEquiv_symm_apply_hom {X : Rep k G} {Y : ModuleCat k}
    (f : X ⟶ (trivialFunctor k G).obj Y) :
    ((coinvariantsAdjunction k G).homEquiv X Y).symm f = desc f := by
  ext
  simp [coinvariantsAdjunction, Adjunction.homEquiv_symm_apply]

instance : (coinvariantsFunctor k G).PreservesZeroMorphisms where
instance : (coinvariantsFunctor k G).IsLeftAdjoint := (coinvariantsAdjunction k G).isLeftAdjoint

/-- The functor sending `A, B` to `(A ⊗[k] B)_G`. This is naturally isomorphic to the functor
sending `A, B` to `A ⊗[k[G]] B`, where we give `A` the `k[G]ᵐᵒᵖ`-module structure defined by
`g • a := A.ρ g⁻¹ a`. -/
noncomputable abbrev coinvariantsTensor : Rep k G ⥤ Rep k G ⥤ ModuleCat k :=
  (Functor.postcompose₂.obj (coinvariantsFunctor k G)).obj (MonoidalCategory.curriedTensor _)

variable {k G} (A B)

/-- The bilinear map sending `a : A, b : B` to `⟦a ⊗ₜ b⟧` in `(A ⊗[k] B)_G`. -/
noncomputable abbrev coinvariantsTensorMk :
    A →ₗ[k] B →ₗ[k] ((coinvariantsTensor k G).obj A).obj B :=
  (TensorProduct.mk k A B).compr₂ (Coinvariants.mk _)

variable {A B}

lemma coinvariantsTensorMk_apply (a : A) (b : B) :
    coinvariantsTensorMk A B a b = Coinvariants.mk _ (a ⊗ₜ[k] b) := rfl

@[ext]
lemma coinvariantsTensor_hom_ext {M : ModuleCat k}
    {f g : ((coinvariantsTensor k G).obj A).obj B ⟶ M}
    (hfg : (coinvariantsTensorMk A B).compr₂ f.hom = (coinvariantsTensorMk A B).compr₂ g.hom) :
    f = g := coinvariantsFunctor_hom_ext <| ModuleCat.hom_ext <| TensorProduct.ext <| hfg

instance (A : Rep k G) : ((coinvariantsTensor k G).obj A).Additive where
instance (A : Rep k G) : ((coinvariantsTensor k G).obj A).Linear k where

section

variable (k : Type u) {G : Type u} [CommRing k] [Group G]

/-- Given a normal subgroup `S ≤ G`, this is the functor sending a `G`-representation `A` to the
`G ⧸ S`-representation it induces on `A_S`. -/
@[simps obj_V map_hom]
noncomputable def quotientToCoinvariantsFunctor (S : Subgroup G) [S.Normal] :
    Rep k G ⥤ Rep k (G ⧸ S) where
  obj X := X.quotientToCoinvariants S
  map {X Y} f := {
    hom := (coinvariantsFunctor k S).map ((Action.res _ S.subtype).map f)
    comm g := QuotientGroup.induction_on g fun g => by
      ext; simp [ModuleCat.endRingEquiv, hom_comm_apply] }

section Finsupp

variable {k} (A : Rep k G) (α : Type u) [DecidableEq α]

open MonoidalCategory Finsupp ModuleCat.MonoidalCategory

/-- Given a `k`-linear `G`-representation `(A, ρ)` and a type `α`, this is the map
`(A ⊗ (α →₀ k[G]))_G →ₗ[k] (α →₀ A)` sending
`⟦a ⊗ single x (single g r)⟧ ↦ single x (r • ρ(g⁻¹)(a)).` -/
noncomputable def coinvariantsTensorFreeToFinsupp :
    (A ⊗ free k G α).ρ.Coinvariants →ₗ[k] (α →₀ A) :=
  (coinvariantsFinsuppLEquiv _ α ≪≫ₗ lcongr (Equiv.refl α)
    (coinvariantsTprodLeftRegularLEquiv A.ρ)).toLinearMap ∘ₗ
    ((coinvariantsFunctor k G).map (finsuppTensorRight A (leftRegular k G) α).hom).hom

variable {A α}

@[simp]
lemma coinvariantsTensorFreeToFinsupp_mk_tmul_single (x : A) (i : α) (g : G) (r : k) :
    DFunLike.coe (F := (A.ρ.tprod (Representation.free k G α)).Coinvariants →ₗ[k] α →₀ A.V)
      (coinvariantsTensorFreeToFinsupp A α) (Coinvariants.mk _ (x ⊗ₜ single i (single g r))) =
      single i (r • A.ρ g⁻¹ x) := by
  simp [tensorObj_def, ModuleCat.MonoidalCategory.tensorObj, coinvariantsTensorFreeToFinsupp,
    Coinvariants.map, finsuppTensorRight, TensorProduct.finsuppRight]

variable (A α)

/-- Given a `k`-linear `G`-representation `(A, ρ)` and a type `α`, this is the map
`(α →₀ A) →ₗ[k] (A ⊗ (α →₀ k[G]))_G` sending `single x a ↦ ⟦a ⊗ₜ single x 1⟧.` -/
noncomputable def finsuppToCoinvariantsTensorFree :
    (α →₀ A) →ₗ[k] Coinvariants (A ⊗ (free k G α)).ρ :=
  ((coinvariantsFunctor k G).map ((finsuppTensorRight A (leftRegular k G) α)).inv).hom ∘ₗ
    (coinvariantsFinsuppLEquiv _ α ≪≫ₗ
    lcongr (Equiv.refl α) (coinvariantsTprodLeftRegularLEquiv A.ρ)).symm.toLinearMap

variable {A α}

@[simp]
lemma finsuppToCoinvariantsTensorFree_single (i : α) (x : A) :
    DFunLike.coe (F := (α →₀ A.V) →ₗ[k] (A.ρ.tprod (Representation.free k G α)).Coinvariants)
      (finsuppToCoinvariantsTensorFree A α) (single i x) =
      Coinvariants.mk _ (x ⊗ₜ single i (single (1 : G) (1 : k))) := by
  simp [finsuppToCoinvariantsTensorFree, Coinvariants.map, ModuleCat.MonoidalCategory.tensorObj,
    tensorObj_def]

variable (A α)

/-- Given a `k`-linear `G`-representation `(A, ρ)` and a type `α`, this is the linear equivalence
`(A ⊗ (α →₀ k[G]))_G ≃ₗ[k] (α →₀ A)` sending
`⟦a ⊗ single x (single g r)⟧ ↦ single x (r • ρ(g⁻¹)(a)).` -/
@[simps! symm_apply]
noncomputable abbrev coinvariantsTensorFreeLEquiv :
    Coinvariants (A ⊗ free k G α).ρ ≃ₗ[k] (α →₀ A) :=
  LinearEquiv.ofLinear (coinvariantsTensorFreeToFinsupp A α) (finsuppToCoinvariantsTensorFree A α)
    (lhom_ext fun i x => by
      simp [finsuppToCoinvariantsTensorFree_single i,
        coinvariantsTensorFreeToFinsupp_mk_tmul_single x]) <|
    Coinvariants.hom_ext <| TensorProduct.ext <| LinearMap.ext fun a => lhom_ext' fun i =>
      lhom_ext fun g r => by
        simp [coinvariantsTensorFreeToFinsupp_mk_tmul_single a,
          finsuppToCoinvariantsTensorFree_single (A := A) i, TensorProduct.smul_tmul]

@[simp]
lemma coinvariantsTensorFreeLEquiv_apply (x : (A ⊗ free k G α).ρ.Coinvariants) :
    DFunLike.coe (F := (A.ρ.tprod (Representation.free k G α)).Coinvariants →ₗ[k] α →₀ A)
      (A.coinvariantsTensorFreeToFinsupp α) x = coinvariantsTensorFreeToFinsupp A α x := by
  rfl

end Finsupp

end

end Rep
