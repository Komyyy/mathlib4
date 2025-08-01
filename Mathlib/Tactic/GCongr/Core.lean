/-
Copyright (c) 2023 Mario Carneiro, Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Heather Macbeth, Jovan Gerbscheid
-/
import Lean
import Batteries.Lean.Except
import Batteries.Tactic.Exact
import Mathlib.Lean.Elab.Term
import Mathlib.Tactic.GCongr.ForwardAttr
import Mathlib.Order.Defs.Unbundled

/-!
# The `gcongr` ("generalized congruence") tactic

The `gcongr` tactic applies "generalized congruence" rules, reducing a relational goal
between a LHS and RHS matching the same pattern to relational subgoals between the differing
inputs to the pattern.  For example,
```
example {a b x c d : ℝ} (h1 : a + 1 ≤ b + 1) (h2 : c + 2 ≤ d + 2) :
    x ^ 2 * a + c ≤ x ^ 2 * b + d := by
  gcongr
  · linarith
  · linarith
```
This example has the goal of proving the relation `≤` between a LHS and RHS both of the pattern
```
x ^ 2 * ?_ + ?_
```
(with inputs `a`, `c` on the left and `b`, `d` on the right); after the use of
`gcongr`, we have the simpler goals `a ≤ b` and `c ≤ d`.

A depth limit, or a pattern can be provided explicitly;
this is useful if a non-maximal match is desired:
```
example {a b c d x : ℝ} (h : a + c + 1 ≤ b + d + 1) :
    x ^ 2 * (a + c) + 5 ≤ x ^ 2 * (b + d) + 5 := by
  gcongr x ^ 2 * ?_ + 5 -- or `gcongr 2`
  linarith
```

## Sourcing the generalized congruence lemmas

Relevant "generalized congruence" lemmas are declared using the attribute `@[gcongr]`.  For
example, the first example constructs the proof term
```
add_le_add (mul_le_mul_of_nonneg_left _ (pow_bit0_nonneg x 1)) _
```
using the generalized congruence lemmas `add_le_add` and `mul_le_mul_of_nonneg_left`. The term
`pow_bit0_nonneg x 1` is automatically generated by a discharger (see below).

When a lemma is tagged `@[gcongr]`, it is verified that that lemma is of "generalized congruence"
form, `f x₁ y z₁ ∼ f x₂ y z₂`, that is, a relation between the application of a function to two
argument lists, in which the "varying argument" pairs (here `x₁`/`x₂` and `z₁`/`z₂`) are all free
variables. The `gcongr` tactic will try a lemma only if it matches the goal in relation `∼`,
head function `f` and the arity of `f`.  It prioritizes lemmas with fewer "varying arguments". Thus,
for example, all three of the following lemmas are tagged `@[gcongr]` and are used in different
situations according to whether the goal compares constant-left-multiplications,
constant-right-multiplications, or fully varying multiplications:
```
theorem mul_le_mul_of_nonneg_left [Mul α] [Zero α] [Preorder α] [PosMulMono α]
    {a b c : α} (h : b ≤ c) (a0 : 0 ≤ a) :
    a * b ≤ a * c

theorem mul_le_mul_of_nonneg_right [Mul α] [Zero α] [Preorder α] [MulPosMono α]
    {a b c : α} (h : b ≤ c) (a0 : 0 ≤ a) :
    b * a ≤ c * a

theorem mul_le_mul [MulZeroClass α] [Preorder α] [PosMulMono α] [MulPosMono α]
    {a b c d : α} (h₁ : a ≤ b) (h₂ : c ≤ d) (c0 : 0 ≤ c) (b0 : 0 ≤ b) :
    a * c ≤ b * d
```
The advantage of this approach is that the lemmas with fewer "varying" input pairs typically require
fewer side conditions, so the tactic becomes more useful by special-casing them.

There can also be more than one generalized congruence lemma dealing with the same relation
and head function, for example with purely notational head
functions which have different theories when different typeclass assumptions apply.  For example,
the following lemma is stored with the same `@[gcongr]` data as `mul_le_mul` above, and the two
lemmas are simply tried in succession to determine which has the typeclasses relevant to the goal:
```
theorem mul_le_mul' [Mul α] [Preorder α] [MulLeftMono α]
    [MulRightMono α] {a b c d : α} (h₁ : a ≤ b) (h₂ : c ≤ d) :
    a * c ≤ b * d
```

## Resolving goals

The tactic attempts to discharge side goals to the "generalized congruence" lemmas (such as the
side goal `0 ≤ x ^ 2` in the above application of `mul_le_mul_of_nonneg_left`) using the tactic
`gcongr_discharger`, which wraps `positivity` but can also be extended. Side goals not discharged
in this way are left for the user.

The tactic also attempts to discharge "main" goals using the available hypotheses, as well as a
limited amount of forward reasoning.  Such attempts are made *before* descending further into
matching by congruence. The built-in forward-reasoning includes reasoning by symmetry and
reflexivity, and this can be extended by writing tactic extensions tagged with the
`@[gcongr_forward]` attribute.

## Introducing variables and hypotheses

Some natural generalized congruence lemmas have "main" hypotheses which are universally quantified
or have the structure of an implication, for example
```
theorem GCongr.Finset.sum_le_sum [OrderedAddCommMonoid N] {f g : ι → N} {s : Finset ι}
    (h : ∀ (i : ι), i ∈ s → f i ≤ g i) :
    s.sum f ≤ s.sum g
```
The tactic automatically introduces the variable `i✝ : ι` and hypothesis `hi✝ : i✝ ∈ s` in the
subgoal `∀ (i : ι), i ∈ s → f i ≤ g i` generated by applying this lemma.  By default this is done
anonymously, so they are inaccessible in the goal state which results.  The user can name them if
needed using the syntax `gcongr with i hi`.

## Variants

The tactic `rel` is a variant of `gcongr`, intended for teaching.  Local hypotheses are not
used automatically to resolve main goals, but must be invoked by name:
```
example {a b x c d : ℝ} (h1 : a ≤ b) (h2 : c ≤ d) :
    x ^ 2 * a + c ≤ x ^ 2 * b + d := by
  rel [h1, h2]
```
The `rel` tactic is finishing-only: it fails if any main or side goals are not resolved.
-/

namespace Mathlib.Tactic.GCongr
open Lean Meta

/-- `GCongrKey` is the key used in the hashmap for looking up `gcongr` lemmas. -/
structure GCongrKey where
  /-- The name of the relation. For example, `a + b ≤ a + c` has ``relName := `LE.le``. -/
  relName : Name
  /-- The name of the head function. For example, `a + b ≤ a + c` has ``head := `HAdd.hAdd``. -/
  head : Name
  /-- The number of arguments that `head` is applied to.
  For example, `a + b ≤ a + c` has `arity := 6`, because `HAdd.hAdd` has 6 arguments. -/
  arity : Nat
deriving Inhabited, BEq, Hashable

/-- Structure recording the data for a "generalized congruence" (`gcongr`) lemma. -/
structure GCongrLemma where
  /-- The key under which the lemma is stored. -/
  key : GCongrKey
  /-- The name of the lemma. -/
  declName : Name
  /-- `mainSubgoals` are the subgoals on which `gcongr` will be recursively called. They store
  - the index of the hypothesis
  - the index of the arguments in the conclusion
  - the number of parameters in the hypothesis -/
  mainSubgoals : Array (Nat × Nat × Nat)
  /-- The number of arguments that `declName` takes when applying it. -/
  numHyps : Nat
  /-- The given priority of the lemma, for example as `@[gcongr high]`. -/
  prio : Nat
  /-- The number of arguments in the application of `head` that are different.
  This is used for sorting the lemmas.
  For example, `a + b ≤ a + c` has `numVarying := 1`. -/
  numVarying : Nat
  deriving Inhabited

/-- A collection of `GCongrLemma`, to be stored in the environment extension. -/
abbrev GCongrLemmas := Std.HashMap GCongrKey (List GCongrLemma)

/-- Return `true` if the priority of `a` is less than or equal to the priority of `b`. -/
def GCongrLemma.prioLE (a b : GCongrLemma) : Bool :=
  (compare a.prio b.prio).then (compare b.numVarying a.numVarying) |>.isLE

/-- Insert a `GCongrLemma` in a collection of lemmas, making sure that the lemmas are sorted. -/
def addGCongrLemmaEntry (m : GCongrLemmas) (l : GCongrLemma) : GCongrLemmas :=
  match m[l.key]? with
  | none    => m.insert l.key [l]
  | some es => m.insert l.key <| insert l es
where
  /--- Insert a `GCongrLemma` in the correct place in a list of lemmas. -/
  insert (l : GCongrLemma) : List GCongrLemma → List GCongrLemma
    | []     => [l]
    | l'::ls => if l'.prioLE l then l::l'::ls else l' :: insert l ls

/-- Environment extension for "generalized congruence" (`gcongr`) lemmas. -/
initialize gcongrExt : SimpleScopedEnvExtension GCongrLemma
    (Std.HashMap GCongrKey (List GCongrLemma)) ←
  registerSimpleScopedEnvExtension {
    addEntry := addGCongrLemmaEntry
    initial := {}
  }

/-- Given an application `f a₁ .. aₙ`, return the name of `f`, and the array of arguments `aᵢ`. -/
def getCongrAppFnArgs (e : Expr) : Option (Name × Array Expr) :=
  match e.cleanupAnnotations with
  | .forallE n d b bi =>
    -- We determine here whether an arrow is an implication or a forall
    -- this approach only works if LHS and RHS are both dependent or both non-dependent
    if b.hasLooseBVars then
      some (`_Forall, #[.lam n d b bi])
    else
      some (`_Implies, #[d, b])
  | e => e.withApp fun f args => f.constName?.map (·, args)

/-- If `e` is of the form `r a b`, return `(r, a, b)`. -/
def getRel (e : Expr) : Option (Name × Expr × Expr) :=
  match e with
  | .app (.app rel lhs) rhs => rel.getAppFn.constName?.map (·, lhs, rhs)
  | .forallE _ lhs rhs _ =>
    if !rhs.hasLooseBVars then
      some (`_Implies, lhs, rhs)
    else
      none
  | _ => none

/-- Construct the `GCongrLemma` data from a given lemma. -/
def makeGCongrLemma (declName : Name) (declTy : Expr) (numHyps prio : Nat) : MetaM GCongrLemma := do
  withReducible <| forallBoundedTelescope declTy numHyps fun xs targetTy => do
    let fail {α} (m : MessageData) : MetaM α := throwError "\
      @[gcongr] attribute only applies to lemmas proving f x₁ ... xₙ ∼ f x₁' ... xₙ'.\n \
      {m} in the conclusion of {declTy}"
    -- verify that conclusion of the lemma is of the form `f x₁ ... xₙ ∼ f x₁' ... xₙ'`
    let some (relName, lhs, rhs) := getRel (← whnf targetTy) | fail "No relation found"
    let some (head, lhsArgs) := getCongrAppFnArgs lhs | fail "LHS is not suitable for congruence"
    let some (head', rhsArgs) := getCongrAppFnArgs rhs | fail "RHS is not suitable for congruence"
    unless head == head' && lhsArgs.size == rhsArgs.size do
      fail "LHS and RHS do not have the same head function and arity"
    let mut numVarying := 0
    let mut pairs := #[]
    -- iterate through each pair of corresponding (LHS/RHS) inputs to the head function `head` in
    -- the conclusion of the lemma
    for i in [:lhsArgs.size] do
      let e1 := lhsArgs[i]!
      let e2 := rhsArgs[i]!
      -- we call such a pair a "varying argument" pair if the LHS/RHS inputs are not defeq
      -- (and not proofs)
      let isEq ← isDefEq e1 e2 <||> (isProof e1 <&&> isProof e2)
      if !isEq then
        -- verify that the "varying argument" pairs are free variables (after eta-reduction)
        let .fvar e1 := e1.eta | fail "Not all arguments are free variables"
        let .fvar e2 := e2.eta | fail "Not all arguments are free variables"
        -- add such a pair to the `pairs` array
        pairs := pairs.push (i, e1, e2)
        numVarying := numVarying + 1
    if numVarying = 0 then
      fail "LHS and RHS are the same"
    let mut mainSubgoals := #[]
    let mut i := 0
    -- iterate over antecedents `hyp` to the lemma
    for hyp in xs do
      mainSubgoals ← forallTelescopeReducing (← inferType hyp) fun args hypTy => do
        -- pull out the conclusion `hypTy` of the antecedent, and check whether it is of the form
        -- `lhs₁ _ ... _ ≈ rhs₁ _ ... _` (for a possibly different relation `≈` than the relation
        -- `rel` above)
        let hypTy ← whnf hypTy
        if let some (_, lhs₁, rhs₁) := getRel hypTy then
          if let .fvar lhs₁ := lhs₁.getAppFn then
          if let .fvar rhs₁ := rhs₁.getAppFn then
          -- check whether `(lhs₁, rhs₁)` is in some order one of the "varying argument" pairs from
          -- the conclusion to the lemma
          if let some j := pairs.find? fun (_, e1, e2) =>
            lhs₁ == e1 && rhs₁ == e2 || lhs₁ == e2 && rhs₁ == e1
          then
            -- if yes, record the index of this antecedent as a "main subgoal", together with the
            -- index of the "varying argument" pair it corresponds to
            return mainSubgoals.push (i, j.1, args.size)
        else
          -- now check whether `hypTy` is of the form `rhs₁ _ ... _`,
          -- and whether the last hypothesis is of the form `lhs₁ _ ... _`.
          if let .fvar rhs₁ := hypTy.getAppFn then
          if let some lastFVar := args.back? then
          if let .fvar lhs₁ := (← inferType lastFVar).getAppFn then
          if let some j := pairs.find? fun (_, e1, e2) =>
            lhs₁ == e1 && rhs₁ == e2 || lhs₁ == e2 && rhs₁ == e1
          then
            return mainSubgoals.push (i, j.1, args.size - 1)
        return mainSubgoals
      i := i + 1
    -- store all the information from this parse of the lemma's structure in a `GCongrLemma`
    let key := { relName, head, arity := lhsArgs.size }
    return { key, declName, mainSubgoals, numHyps, prio, numVarying }


/-- Attribute marking "generalized congruence" (`gcongr`) lemmas.  Such lemmas must have a
conclusion of a form such as `f x₁ y z₁ ∼ f x₂ y z₂`; that is, a relation between the application of
a function to two argument lists, in which the "varying argument" pairs (here `x₁`/`x₂` and
`z₁`/`z₂`) are all free variables.

The antecedents of such a lemma are classified as generating "main goals" if they are of the form
`x₁ ≈ x₂` for some "varying argument" pair `x₁`/`x₂` (and a possibly different relation `≈` to `∼`),
or more generally of the form `∀ i h h' j h'', f₁ i j ≈ f₂ i j` (say) for some "varying argument"
pair `f₁`/`f₂`. (Other antecedents are considered to generate "side goals".) The index of the
"varying argument" pair corresponding to each "main" antecedent is recorded.

Lemmas involving `<` or `≤` can also be marked `@[bound]` for use in the related `bound` tactic. -/
initialize registerBuiltinAttribute {
  name := `gcongr
  descr := "generalized congruence"
  add := fun decl stx kind ↦ MetaM.run' do
    let prio ← getAttrParamOptPrio stx[1]
    let declTy := (← getConstInfo decl).type
    let arity := declTy.getForallArity
    -- We have to determine how many of the hypotheses should be introduced for
    -- processing the `gcongr` lemma. This is because of implication lemmas like `Or.imp`,
    -- which we treat as having conclusion `a ∨ b → c ∨ d` instead of just `c ∨ d`.
    -- Since there is only one possible arity at which the `gcongr` lemma will be accepted,
    -- we simply attempt to process the lemmas at the different possible arities.
    try
      gcongrExt.add (← makeGCongrLemma decl declTy arity prio) kind
    catch e => try
      guard (1 ≤ arity)
      gcongrExt.add (← makeGCongrLemma decl declTy (arity - 1) prio) kind
    catch _ => try
      -- We need to use `arity - 2` for lemmas such as `imp_imp_imp` and `forall_imp`.
      guard (2 ≤ arity)
      gcongrExt.add (← makeGCongrLemma decl declTy (arity - 2) prio) kind
    catch _ =>
      -- If none of the arities work, we throw the error of the first attempt.
      throw e
}

initialize registerTraceClass `Meta.gcongr

syntax "gcongr_discharger" : tactic

/--
This is used as the default side-goal discharger,
it calls the `gcongr_discharger` extensible tactic.
-/
def gcongrDischarger (goal : MVarId) : MetaM Unit := Elab.Term.TermElabM.run' do
  trace[Meta.gcongr] "Attempting to discharge side goal {goal}"
  let [] ← Elab.Tactic.run goal <|
      Elab.Tactic.evalTactic (Unhygienic.run `(tactic| gcongr_discharger))
    | failure

open Elab Tactic

/-- See if the term is `a = b` and the goal is `a ∼ b` or `b ∼ a`, with `∼` reflexive. -/
@[gcongr_forward] def exactRefl : ForwardExt where
  eval h goal := do
    let m ← mkFreshExprMVar none
    goal.assignIfDefEq (← mkAppOptM ``Eq.subst #[h, m])
    goal.applyRfl

/-- See if the term is `a ∼ b` with `∼` symmetric and the goal is `b ∼ a`. -/
@[gcongr_forward] def symmExact : ForwardExt where
  eval h goal := do (← goal.applySymm).assignIfDefEq h

@[gcongr_forward] def exact : ForwardExt where
  eval e m := m.assignIfDefEq e

/-- Attempt to resolve an (implicitly) relational goal by one of a provided list of hypotheses,
either with such a hypothesis directly or by a limited palette of relational forward-reasoning from
these hypotheses. -/
def _root_.Lean.MVarId.gcongrForward (hs : Array Expr) (g : MVarId) : MetaM Unit :=
  withReducible do
    let s ← saveState
    withTraceNode `Meta.gcongr (fun _ => return m!"gcongr_forward: ⊢ {← g.getType}") do
    -- Iterate over a list of terms
    let tacs := (forwardExt.getState (← getEnv)).2
    for h in hs do
      try
        tacs.firstM fun (n, tac) =>
          withTraceNode `Meta.gcongr (return m!"{·.emoji} trying {n} on {h} : {← inferType h}") do
            tac.eval h g
        return
      catch _ => s.restore
    throwError "gcongr_forward failed"

/--
This is used as the default main-goal discharger,
consisting of running `Lean.MVarId.gcongrForward` (trying a term together with limited
forward-reasoning on that term) on each nontrivial hypothesis.
-/
def gcongrForwardDischarger (goal : MVarId) : MetaM Unit := Elab.Term.TermElabM.run' do
  let mut hs := #[]
  -- collect the nontrivial hypotheses
  for h in ← getLCtx do
    if !h.isImplementationDetail then
      hs := hs.push (.fvar h.fvarId)
  -- run `Lean.MVarId.gcongrForward` on each one
  goal.gcongrForward hs

/-- Determine whether `template` contains a `?_`.
This guides the `gcongr` tactic when it is given a template. -/
def containsHole (template : Expr) : MetaM Bool := do
  let mctx ← getMCtx
  let hasMVar := template.findMVar? fun mvarId =>
    if let some mdecl := mctx.findDecl? mvarId then
      mdecl.kind matches .syntheticOpaque
    else
      false
  return hasMVar.isSome

section Trans

/-!
The lemmas `rel_imp_rel`, `rel_trans` and `rel_trans'` are too general to be tagged with
`@[gcongr]`, so instead we use `getTransLemma?` to look up these lemmas.
-/

variable {α : Sort*} {r : α → α → Prop} [IsTrans α r] {a b c d : α}

lemma rel_imp_rel (h₁ : r c a) (h₂ : r b d) : r a b → r c d :=
  fun h => IsTrans.trans c b d (IsTrans.trans c a b h₁ h) h₂

/--
Construct a `GCongrLemma` for `gcongr` goals of the form `a ≺ b → c ≺ d`.
This will be tried if there is no other available `@[gcongr]` lemma.
For example, the relation `a ≡ b [ZMOD n]` has an instance of `IsTrans`, so a congruence of the form
`a ≡ b [ZMOD n] → c ≡ d [ZMOD n]` can be solved with `rel_imp_rel`, `rel_trans` or `rel_trans'`.
-/
def relImpRelLemma (arity : Nat) : List GCongrLemma :=
  if arity < 2 then [] else [{
    declName := ``rel_imp_rel
    mainSubgoals := #[(7, arity - 2, 0), (8, arity - 1, 0)]
    numHyps := 9
    key := default, prio := default, numVarying := default
  }]

end Trans

open private isDefEqApply throwApplyError reorderGoals from Lean.Meta.Tactic.Apply in
/--
`Lean.MVarId.applyWithArity` is a copy of `Lean.MVarId.apply`, where the arity of the
applied function is given explicitly instead of being inferred.

TODO: make `Lean.MVarId.apply` take a configuration argument to do this itself
-/
def _root_.Lean.MVarId.applyWithArity (mvarId : MVarId) (e : Expr) (arity : Nat)
    (cfg : ApplyConfig := {}) (term? : Option MessageData := none) : MetaM (List MVarId) :=
  mvarId.withContext do
    mvarId.checkNotAssigned `apply
    let targetType ← mvarId.getType
    let eType      ← inferType e
    let (newMVars, binderInfos) ← do
      let (newMVars, binderInfos, eType) ← forallMetaTelescopeReducing eType arity
      if (← isDefEqApply cfg.approx eType targetType) then
        pure (newMVars, binderInfos)
      else
        let conclusionType? ← if arity = 0 then
          pure none
        else
          let (_, _, r) ← forallMetaTelescopeReducing eType arity
          pure (some r)
        throwApplyError mvarId eType conclusionType? targetType term?
    postprocessAppMVars `apply mvarId newMVars binderInfos
      cfg.synthAssignedInstances cfg.allowSynthFailures
    let e ← instantiateMVars e
    mvarId.assign (mkAppN e newMVars)
    let newMVars ← newMVars.filterM fun mvar => not <$> mvar.mvarId!.isAssigned
    let otherMVarIds ← getMVarsNoDelayed e
    let newMVarIds ← reorderGoals newMVars cfg.newGoals
    let otherMVarIds := otherMVarIds.filter fun mvarId => !newMVarIds.contains mvarId
    let result := newMVarIds ++ otherMVarIds.toList
    result.forM (·.headBetaType)
    return result

/-- The core of the `gcongr` tactic.  Parse a goal into the form `(f _ ... _) ∼ (f _ ... _)`,
look up any relevant `@[gcongr]` lemmas, try to apply them, recursively run the tactic itself on
"main" goals which are generated, and run the discharger on side goals which are generated. If there
is a user-provided template, first check that the template asks us to descend this far into the
match. -/
partial def _root_.Lean.MVarId.gcongr
    (g : MVarId) (template : Option Expr) (names : List (TSyntax ``binderIdent))
    (depth : Nat := 1000000)
    (grewriteHole : Option MVarId := none)
    (mainGoalDischarger : MVarId → MetaM Unit := gcongrForwardDischarger)
    (sideGoalDischarger : MVarId → MetaM Unit := gcongrDischarger) :
    MetaM (Bool × List (TSyntax ``binderIdent) × Array MVarId) := g.withContext do
  withTraceNode `Meta.gcongr (fun _ => return m!"gcongr: ⊢ {← g.getType}") do
  match template with
  | none =>
    -- A. If there is no template, try to resolve the goal by the provided tactic
    -- `mainGoalDischarger`, and continue on if this fails.
    try
      (withReducible g.applyRfl) <|> mainGoalDischarger g
      return (true, names, #[])
    catch _ => pure ()
  | some tpl =>
    -- B. If there is a template:
    -- (i) if the template is `?_` (or `?_ x1 x2`, created by entering binders)
    -- then try to resolve the goal by the provided tactic `mainGoalDischarger`;
    -- if this fails, stop and report the existing goal.
    if let .mvar mvarId := tpl.getAppFn then
      if let some hole := grewriteHole then
        if hole == mvarId then mainGoalDischarger g; return (true, names, #[])
      else
        if let .syntheticOpaque ← mvarId.getKind then
          try mainGoalDischarger g; return (true, names, #[])
          catch _ => return (false, names, #[g])
    -- B. If the template doesn't contain any `?_`, and the goal wasn't closed by `rfl`,
    -- we report that the provided pattern doesn't apply.
    let hasHole ← match grewriteHole with
      | none => containsHole tpl
      | some hole => pure (tpl.findMVar? (· == hole)).isSome
    unless hasHole do
      try withDefault g.applyRfl; return (true, names, #[])
      catch _ => throwTacticEx `gcongr g m!"\
        subgoal {← withReducible g.getType'} is not allowed by the provided pattern \
        and is not closed by `rfl`"
    -- (ii) if the template is *not* `?_` then continue on.
  match depth with
  | 0 => try mainGoalDischarger g; return (true, names, #[]) catch _ => return (false, names, #[g])
  | depth + 1 =>
  -- Check that the goal is of the form `rel (lhsHead _ ... _) (rhsHead _ ... _)`
  let rel ← withReducible g.getType'
  let some (relName, lhs, rhs) := getRel rel | throwTacticEx `gcongr g m!"{rel} is not a relation"
  let some (lhsHead, lhsArgs) := getCongrAppFnArgs lhs
    | if template.isNone then return (false, names, #[g])
      throwTacticEx `gcongr g m!"the head of {lhs} is not a constant"
  let some (rhsHead, rhsArgs) := getCongrAppFnArgs rhs
    | if template.isNone then return (false, names, #[g])
      throwTacticEx `gcongr g m!"the head of {rhs} is not a constant"
  -- B. If there is a template, check that it is of the form `tplHead _ ... _` and that
  -- `tplHead = lhsHead = rhsHead`
  let tplArgs ← if let some tpl := template then
    let some (tplHead, tplArgs) := getCongrAppFnArgs tpl
      | throwTacticEx `gcongr g m!"the head of {tpl} is not a constant"
    if grewriteHole.isNone then
      unless tplHead == lhsHead && tplArgs.size == lhsArgs.size do
        throwError "expected {tplHead}, got {lhsHead}\n{lhs}"
      unless tplHead == rhsHead && tplArgs.size == rhsArgs.size do
        throwError "expected {tplHead}, got {rhsHead}\n{rhs}"
    pure <| tplArgs.map some
  -- A. If there is no template, check that `lhs` and `rhs` have the same shape
  else
    unless lhsHead == rhsHead && lhsArgs.size == rhsArgs.size do
      -- (if not, stop and report the existing goal)
      return (false, names, #[g])
    pure <| Array.replicate lhsArgs.size none
  let s ← saveState
  -- Look up the `@[gcongr]` lemmas whose conclusion has the same relation and head function as
  -- the goal
  let key := { relName, head := lhsHead, arity := tplArgs.size }
  let mut lemmas := (gcongrExt.getState (← getEnv)).getD key []
  if relName == `_Implies then
    lemmas := lemmas ++ relImpRelLemma tplArgs.size
  for lem in lemmas do
    let gs ← try
      -- Try `apply`-ing such a lemma to the goal.
      let const ← mkConstWithFreshMVarLevels lem.declName
      Except.ok <$> withReducible
        (g.applyWithArity const lem.numHyps { synthAssignedInstances := false })
    catch e => pure (Except.error e)
    match gs with
    | .error _ =>
      -- If the `apply` fails, go on to try to apply the next matching lemma.
      s.restore
    | .ok gs =>
      let some e ← getExprMVarAssignment? g | panic! "unassigned?"
      let args := e.getAppArgs
      let mut subgoals := #[]
      let mut names := names
      -- If the `apply` succeeds, iterate over `(i, j)` belonging to the lemma's `mainSubgoal`
      -- list: here `i` is an index in the lemma's array of antecedents, and `j` is an index in
      -- the array of arguments to the head function in the conclusion of the lemma (this should
      -- be the same as the head function of the LHS and RHS of our goal), such that the `i`-th
      -- antecedent to the lemma is a relation between the LHS and RHS `j`-th inputs to the head
      -- function in the goal.
      for (i, j, numHyps) in lem.mainSubgoals do
        -- We anticipate that such a "main" subgoal should not have been solved by the `apply` by
        -- unification ...
        let some (.mvar mvarId) := args[i]? | panic! "what kind of lemma is this?"
        -- Introduce all variables and hypotheses in this subgoal.
        let (names2, _vs, mvarId) ← mvarId.introsWithBinderIdents names (maxIntros? := numHyps)
        -- B. If there is a template, look up the part of the template corresponding to the `j`-th
        -- input to the head function
        let tpl ← tplArgs[j]!.mapM fun e => do
          let (_vs, _, e) ← lambdaMetaTelescope e
          pure e
        -- Recurse: call ourself (`Lean.MVarId.gcongr`) on the subgoal with (if available) the
        -- appropriate template
        let (_, names2, subgoals2) ← mvarId.gcongr tpl names2 depth grewriteHole mainGoalDischarger
          sideGoalDischarger
        (names, subgoals) := (names2, subgoals ++ subgoals2)
      let mut out := #[]
      -- Also try the discharger on any "side" (i.e., non-"main") goals which were not resolved
      -- by the `apply`.
      for g in gs do
        if !(← g.isAssigned) && !subgoals.contains g then
          let s ← saveState
          try
            let (_, g') ← g.intros
            sideGoalDischarger g'
          catch _ =>
            s.restore
            out := out.push g
      -- Return all unresolved subgoals, "main" or "side"
      return (true, names, out ++ subgoals)
  -- A. If there is no template, and there was no `@[gcongr]` lemma which matched the goal,
  -- report this goal back.
  if template.isNone then
    return (false, names, #[g])
  -- B. If there is a template, and there was no `@[gcongr]` lemma which matched the template,
  -- fail.
  if lemmas.isEmpty then
    throwTacticEx `gcongr g m!"there is no `@[gcongr]` lemma \
      for relation '{relName}' and constant '{lhsHead}'."
  else
    throwTacticEx `gcongr g m!"none of the `@[gcongr]` lemmas were applicable to the goal {rel}.\
      \n  attempted lemmas: {lemmas.map (·.declName)}"

/-- The `gcongr` tactic applies "generalized congruence" rules, reducing a relational goal
between a LHS and RHS.  For example,
```
example {a b x c d : ℝ} (h1 : a + 1 ≤ b + 1) (h2 : c + 2 ≤ d + 2) :
    x ^ 2 * a + c ≤ x ^ 2 * b + d := by
  gcongr
  · linarith
  · linarith
```
This example has the goal of proving the relation `≤` between a LHS and RHS both of the pattern
```
x ^ 2 * ?_ + ?_
```
(with inputs `a`, `c` on the left and `b`, `d` on the right); after the use of
`gcongr`, we have the simpler goals `a ≤ b` and `c ≤ d`.

A depth limit or a pattern can be provided explicitly;
this is useful if a non-maximal match is desired:
```
example {a b c d x : ℝ} (h : a + c + 1 ≤ b + d + 1) :
    x ^ 2 * (a + c) + 5 ≤ x ^ 2 * (b + d) + 5 := by
  gcongr x ^ 2 * ?_ + 5 -- or `gcongr 2`
  linarith
```

The "generalized congruence" rules are the library lemmas which have been tagged with the
attribute `@[gcongr]`.  For example, the first example constructs the proof term
```
add_le_add (mul_le_mul_of_nonneg_left ?_ (Even.pow_nonneg (even_two_mul 1) x)) ?_
```
using the generalized congruence lemmas `add_le_add` and `mul_le_mul_of_nonneg_left`.

The tactic attempts to discharge side goals to these "generalized congruence" lemmas (such as the
side goal `0 ≤ x ^ 2` in the above application of `mul_le_mul_of_nonneg_left`) using the tactic
`gcongr_discharger`, which wraps `positivity` but can also be extended. Side goals not discharged
in this way are left for the user.

`gcongr` will descend into binders (for example sums or suprema). To name the bound variables,
use `with`:
```
example {f g : ℕ → ℝ≥0∞} (h : ∀ n, f n ≤ g n) : ⨆ n, f n ≤ ⨆ n, g n := by
  gcongr with i
  exact h i
```
-/
elab "gcongr" template:(ppSpace colGt term)?
    withArg:((" with" (ppSpace colGt binderIdent)+)?) : tactic => do
  let g ← getMainGoal
  g.withContext do
  let some (_rel, lhs, _rhs) := getRel (← withReducible g.getType')
    | throwError "gcongr failed, not a relation"
  -- Get the names from the `with x y z` list
  let names := (withArg.raw[1].getArgs.map TSyntax.mk).toList
  -- Time to actually run the core tactic `Lean.MVarId.gcongr`!
  let (progress, _, unsolvedGoalStates) ← match template with
    | none => g.gcongr none names
    | some e => match e.raw.isNatLit? with
      | some depth => g.gcongr none names (depth := depth)
      | none =>
        -- Elaborate the template (e.g. `x * ?_ + _`)
        let template ← Term.elabPattern e (← inferType lhs)
        unless ← containsHole template do
          throwError "invalid template {template}, it doesn't contain any `?_`"
        g.gcongr template names
  if progress then
    replaceMainGoal unsolvedGoalStates.toList
  else
    throwError "gcongr did not make progress"

/-- The `rel` tactic applies "generalized congruence" rules to solve a relational goal by
"substitution".  For example,
```
example {a b x c d : ℝ} (h1 : a ≤ b) (h2 : c ≤ d) :
    x ^ 2 * a + c ≤ x ^ 2 * b + d := by
  rel [h1, h2]
```
In this example we "substitute" the hypotheses `a ≤ b` and `c ≤ d` into the LHS `x ^ 2 * a + c` of
the goal and obtain the RHS `x ^ 2 * b + d`, thus proving the goal.

The "generalized congruence" rules used are the library lemmas which have been tagged with the
attribute `@[gcongr]`.  For example, the first example constructs the proof term
```
add_le_add (mul_le_mul_of_nonneg_left h1 (pow_bit0_nonneg x 1)) h2
```
using the generalized congruence lemmas `add_le_add` and `mul_le_mul_of_nonneg_left`.  If there are
no applicable generalized congruence lemmas, the tactic fails.

The tactic attempts to discharge side goals to these "generalized congruence" lemmas (such as the
side goal `0 ≤ x ^ 2` in the above application of `mul_le_mul_of_nonneg_left`) using the tactic
`gcongr_discharger`, which wraps `positivity` but can also be extended. If the side goals cannot
be discharged in this way, the tactic fails. -/
syntax "rel" " [" term,* "]" : tactic

elab_rules : tactic
  | `(tactic| rel [$hyps,*]) => do
    let g ← getMainGoal
    g.withContext do
    let hyps ← hyps.getElems.mapM (elabTerm · none)
    let some (_rel, lhs, rhs) := getRel (← withReducible g.getType')
      | throwError "rel failed, goal not a relation"
    unless ← isDefEq (← inferType lhs) (← inferType rhs) do
      throwError "rel failed, goal not a relation"
    -- The core tactic `Lean.MVarId.gcongr` will be run with main-goal discharger being the tactic
    -- consisting of running `Lean.MVarId.gcongrForward` (trying a term together with limited
    -- forward-reasoning on that term) on each of the listed terms.
    let assum g := g.gcongrForward hyps
    -- Time to actually run the core tactic `Lean.MVarId.gcongr`!
    let (_, _, unsolvedGoalStates) ← g.gcongr none [] (mainGoalDischarger := assum)
    match unsolvedGoalStates.toList with
    -- if all goals are solved, succeed!
    | [] => pure ()
    -- if not, fail and report the unsolved goals
    | unsolvedGoalStates => do
      let unsolvedGoals ← liftMetaM <| List.mapM MVarId.getType unsolvedGoalStates
      let g := Lean.MessageData.joinSep (unsolvedGoals.map Lean.MessageData.ofExpr) Format.line
      throwError "rel failed, cannot prove goal by 'substituting' the listed relationships. \
        The steps which could not be automatically justified were:\n{g}"

end GCongr

end Mathlib.Tactic
