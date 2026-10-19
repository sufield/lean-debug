import Lean
open Lean Elab Command

namespace LeanDebug

private def symbols : Array (String × String × String) := #[
  ("→",  "\\to",      "function type, implication"),
  ("←",  "\\l",       "reverse arrow, have/let binding"),
  ("↔",  "\\iff",     "if and only if"),
  ("∀",  "\\forall",  "universal quantifier"),
  ("∃",  "\\exists",  "existential quantifier"),
  ("λ",  "\\lam",     "lambda abstraction"),
  ("α",  "\\a",       "type variable"),
  ("β",  "\\b",       "type variable"),
  ("γ",  "\\g",       "type variable"),
  ("δ",  "\\d",       "type variable"),
  ("ε",  "\\e",       "epsilon"),
  ("σ",  "\\si",      "type variable"),
  ("τ",  "\\t",       "type variable"),
  ("ω",  "\\om",      "omega"),
  ("Σ",  "\\Si",      "sigma type (dependent pair)"),
  ("Π",  "\\Pi",      "pi type (dependent function)"),
  ("⟨",  "\\<",       "anonymous constructor open"),
  ("⟩",  "\\>",       "anonymous constructor close"),
  ("≤",  "\\le",      "less than or equal"),
  ("≥",  "\\ge",      "greater than or equal"),
  ("≠",  "\\ne",      "not equal"),
  ("≈",  "\\~~",      "approximate equality"),
  ("∧",  "\\and",     "logical and (conjunction)"),
  ("∨",  "\\or",      "logical or (disjunction)"),
  ("¬",  "\\not",     "logical negation"),
  ("⊢",  "\\vdash",   "turnstile (proves/entails)"),
  ("⊥",  "\\bot",     "false / bottom type"),
  ("⊤",  "\\top",     "true / top type"),
  ("∈",  "\\in",      "set membership"),
  ("∉",  "\\notin",   "not a member of"),
  ("⊆",  "\\sub",     "subset or equal"),
  ("∩",  "\\cap",     "set intersection"),
  ("∪",  "\\cup",     "set union"),
  ("∅",  "\\empty",   "empty set"),
  ("⬝",  "\\tr",      "path composition"),
  ("▸",  "\\t",       "substitution (rewrite in goal)"),
  ("·",  "\\.",       "placeholder / function composition"),
  ("×",  "\\x",       "product type"),
  ("ℕ",  "\\N",       "natural numbers"),
  ("ℤ",  "\\Z",       "integers"),
  ("ℚ",  "\\Q",       "rationals"),
  ("ℝ",  "\\R",       "reals"),
  ("ℂ",  "\\C",       "complex numbers"),
  ("∘",  "\\o",       "function composition"),
  ("†",  "\\dag",     "dagger / adjoint"),
  ("‖",  "\\||",      "norm"),
  ("⁻¹", "\\-1",      "inverse")
]

elab "#cheatsheet" : command => do
  let header := "Symbol  Input       Meaning"
  let sep    := "──────  ──────────  ──────────────────────────"
  let rows := symbols.map fun (sym, input, desc) =>
    let symPad := sym ++ String.ofList (List.replicate (6 - sym.length) ' ')
    let inputPad := input ++ String.ofList (List.replicate (12 - input.length) ' ')
    s!"{symPad}{inputPad}{desc}"
  let table := String.intercalate "\n" (header :: sep :: rows.toList)
  logInfo m!"Lean 4 Unicode Input Reference\n\n{table}"

end LeanDebug
