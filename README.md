# LeanDebug

AI-powered `#debug` command and `debug` tactic for Lean 4. Place them in your file to get LLM explanations of compiler errors and tactic goals directly in InfoView.

## Requirements

- Lean 4.35+
- Go 1.22+ (to build the `lean-explain` CLI)
- `ANTHROPIC_API_KEY` environment variable set

## Install

### 1. Build the Go CLI

```bash
cd lean-explain/cmd/lean-explain
go build -o lean-explain .
cp lean-explain ~/.local/bin/   # or anywhere on PATH
```

### 2. Add as a Lake dependency

In your project's `lakefile.toml`:

```toml
[[require]]
name = "LeanDebug"
path = "/path/to/lean-debug"
```

Then `lake build` to fetch it.

## Usage

### `#debug` — explain compiler errors

Place `#debug` after code that has errors. It collects all diagnostics above it, sends them to Claude, and prints the explanation in InfoView.

```lean
import LeanDebug

def foo : Nat := "hello"

#debug
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
3. Pipes it to the `lean-explain` binary via stdin
4. `lean-explain` calls the Claude API and returns the explanation
5. The result appears in InfoView via `logInfo`
