import Lean
open Lean Elab Command

namespace LeanDebug

private def symbols : Array (String × String) := #[
  ("→",  "\\to"),
  ("←",  "\\l"),
  ("↔",  "\\iff"),
  ("∀",  "\\forall"),
  ("∃",  "\\exists"),
  ("λ",  "\\lam"),
  ("α",  "\\a"),
  ("β",  "\\b"),
  ("γ",  "\\g"),
  ("δ",  "\\d"),
  ("ε",  "\\e"),
  ("σ",  "\\si"),
  ("τ",  "\\t"),
  ("ω",  "\\om"),
  ("Σ",  "\\Si"),
  ("Π",  "\\Pi"),
  ("⟨",  "\\<"),
  ("⟩",  "\\>"),
  ("≤",  "\\le"),
  ("≥",  "\\ge"),
  ("≠",  "\\ne"),
  ("≈",  "\\~~"),
  ("∧",  "\\and"),
  ("∨",  "\\or"),
  ("¬",  "\\not"),
  ("⊢",  "\\vdash"),
  ("⊥",  "\\bot"),
  ("⊤",  "\\top"),
  ("∈",  "\\in"),
  ("∉",  "\\notin"),
  ("⊆",  "\\sub"),
  ("∩",  "\\cap"),
  ("∪",  "\\cup"),
  ("∅",  "\\empty"),
  ("⬝",  "\\tr"),
  ("▸",  "\\t"),
  ("·",  "\\."),
  ("×",  "\\x"),
  ("ℕ",  "\\N"),
  ("ℤ",  "\\Z"),
  ("ℚ",  "\\Q"),
  ("ℝ",  "\\R"),
  ("ℂ",  "\\C"),
  ("∘",  "\\o"),
  ("†",  "\\dag"),
  ("‖",  "\\||"),
  ("⁻¹", "\\-1")
]

elab "#cheatsheet" : command => do
  let rows := symbols.map fun (sym, input) => s!"{sym}  {input}"
  let table := String.intercalate "\n" rows.toList
  logInfo m!"Lean 4 Unicode Input Reference\n\n{table}"

end LeanDebug
