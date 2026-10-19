# LeanDebug

AI-powered `#debug` command and `debug` tactic for Lean 4. Place them in your file to get LLM explanations of compiler errors and tactic goals directly in InfoView.

Pure Lean 4 — no external binaries. Uses `curl` (present on every system) to call the Claude API.

## Requirements

- Lean 4.35+
- `curl` on PATH
- `ANTHROPIC_API_KEY` environment variable set

## Install

In your project's `lakefile.toml`:

```toml
[[require]]
name = "LeanDebug"
git = "https://github.com/sufield/lean-debug"
rev = "main"
```

Then `lake update && lake build`.

## Usage

### `#debug` — explain compiler errors

Wrap the problematic code with `#debug`. It elaborates the command, captures any errors, sends them to Claude, and prints the explanation in InfoView.

```lean
import LeanDebug

#debug def foo : Nat := "hello"
-- InfoView shows: WHY Lean rejected this, the type mismatch, and the fix
```

### `debug` — explain tactic goals

Use `debug` inside a tactic proof to get an explanation of the current goal state and a suggested next step.

```lean
import LeanDebug

theorem bar (p q : Prop) (hp : p) (hq : q) : p ∧ q := by
  debug
  -- InfoView shows: goal explanation + suggested tactic
  exact ⟨hp, hq⟩
```

The `debug` tactic is read-only — it does not close or modify the goal.

### `#cheatsheet` — unicode input reference

Displays a symbol → keystroke table in InfoView. No API key needed.

```lean
import LeanDebug

#cheatsheet
-- InfoView shows: →  \to, ←  \l, ∀  \forall, ...
```

## How it works

1. The Lean elaborator gathers diagnostics and/or goal state
2. Builds a JSON payload with source context (±10 lines)
3. Calls `curl` against the Claude API via `IO.Process.output`
4. Parses the response with `Lean.Json`
5. The result appears in InfoView via `logInfo`
