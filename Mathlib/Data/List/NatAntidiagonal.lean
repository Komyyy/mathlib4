/-
Copyright (c) 2019 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import Mathlib.Data.List.Nodup

/-!
# Antidiagonals in ℕ × ℕ as lists

This file defines the antidiagonals of ℕ × ℕ as lists: the `n`-th antidiagonal is the list of
pairs `(i, j)` such that `i + j = n`. This is useful for polynomial multiplication and more
generally for sums going from `0` to `n`.

## Notes

Files `Data.Multiset.NatAntidiagonal` and `Data.Finset.NatAntidiagonal` successively turn the
`List` definition we have here into `Multiset` and `Finset`.
-/

open Function

namespace List

namespace Nat

/-- The antidiagonal of a natural number `n` is the list of pairs `(i, j)` such that `i + j = n`. -/
def antidiagonal (n : ℕ) : List (ℕ × ℕ) :=
  (range (n + 1)).map fun i ↦ (i, n - i)

/-- A pair (i, j) is contained in the antidiagonal of `n` if and only if `i + j = n`. -/
@[simp]
theorem mem_antidiagonal {n : ℕ} {x : ℕ × ℕ} : x ∈ antidiagonal n ↔ x.1 + x.2 = n := by
  rw [antidiagonal, mem_map]; constructor
  · rintro ⟨i, hi, rfl⟩
    rw [mem_range, Nat.lt_succ_iff] at hi
    exact Nat.add_sub_cancel' hi
  · rintro rfl
    refine ⟨x.fst, ?_, ?_⟩
    · rw [mem_range]
      omega
    · exact Prod.ext rfl (by simp only [Nat.add_sub_cancel_left])

/-- The length of the antidiagonal of `n` is `n + 1`. -/
@[simp]
theorem length_antidiagonal (n : ℕ) : (antidiagonal n).length = n + 1 := by
  rw [antidiagonal, length_map, length_range]

/-- The antidiagonal of `0` is the list `[(0, 0)]` -/
@[simp]
theorem antidiagonal_zero : antidiagonal 0 = [(0, 0)] :=
  rfl

/-- The antidiagonal of `n` does not contain duplicate entries. -/
theorem nodup_antidiagonal (n : ℕ) : Nodup (antidiagonal n) :=
  nodup_range.map ((@LeftInverse.injective ℕ (ℕ × ℕ) Prod.fst fun i ↦ (i, n - i)) fun _ ↦ rfl)

@[simp]
theorem antidiagonal_succ {n : ℕ} :
    antidiagonal (n + 1) = (0, n + 1) :: (antidiagonal n).map (Prod.map Nat.succ id) := by
  simp only [antidiagonal, range_succ_eq_map, map_cons, Nat.add_succ_sub_one,
    Nat.add_zero, id, Nat.sub_zero, map_map, Prod.map_apply]
  apply congr rfl (congr rfl _)
  ext; simp

theorem antidiagonal_succ' {n : ℕ} :
    antidiagonal (n + 1) = (antidiagonal n).map (Prod.map id Nat.succ) ++ [(n + 1, 0)] := by
  simp only [antidiagonal, range_succ, Nat.add_sub_cancel_left, map_append, append_assoc,
    Nat.sub_self, singleton_append, map_map, map]
  congr 1
  apply map_congr_left
  simp +contextual [le_of_lt, Nat.sub_add_comm]

theorem antidiagonal_succ_succ' {n : ℕ} :
    antidiagonal (n + 2) =
      (0, n + 2) :: (antidiagonal n).map (Prod.map Nat.succ Nat.succ) ++ [(n + 2, 0)] := by
  rw [antidiagonal_succ']
  simp only [antidiagonal_succ, map_cons, Prod.map_apply, id_eq, map_map, cons_append, cons.injEq,
    append_cancel_right_eq, true_and]
  ext
  simp

theorem map_swap_antidiagonal {n : ℕ} :
    (antidiagonal n).map Prod.swap = (antidiagonal n).reverse := by
  rw [antidiagonal, map_map, ← List.map_reverse, range_eq_range', reverse_range', ←
    range_eq_range', map_map]
  apply map_congr_left
  simp +contextual [Nat.sub_sub_self, Nat.lt_succ_iff]

end Nat

end List
