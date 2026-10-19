# LeanDebug

AI-powered `#debug` command and `debug` tactic for Lean 4. Get LLM explanations of compiler errors and tactic goals directly in InfoView.

Pure Lean 4 — no external binaries. Uses `curl` to call the Claude API.

## Requirements

- Lean 4.35+
- `curl` on PATH
- `ANTHROPIC_API_KEY` environment variable (workspace-scoped key from console.anthropic.com)

## Install

In your project's `lakefile.toml`:

```toml
[[require]]
name = "LeanDebug"
git = "https://github.com/sufield/lean-debug"
rev = "main"
```

Then `lake update && lake build`.

## Setup

Export your API key so the Lean Language Server can see it:

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

Restart VS Code after adding the key. If using a user-scoped key (`sk-ant-usr-*`), also set `ANTHROPIC_WORKSPACE_ID`.

## Usage

### `#debug` — explain compiler errors

Prefix the problematic code with `#debug`. It elaborates the command, captures errors, sends them to Claude, and prints the explanation in InfoView.

```lean
import LeanDebug

#debug def foo : Nat := "hello"
-- InfoView: explains the type mismatch and shows the fix
```

### `debug` — explain tactic goals

Use `debug` inside a tactic proof to get an explanation of the current goal state and a suggested next step.

```lean
import LeanDebug

theorem bar (p q : Prop) (hp : p) (hq : q) : p ∧ q := by
  debug
  -- InfoView: explains the goal and suggests tactics
  exact ⟨hp, hq⟩
```

The `debug` tactic is read-only — it does not close or modify the goal.

### `#cheatsheet` — unicode input reference

Displays a three-column table (symbol, keystroke, meaning) in InfoView. No API key needed.

```lean
import LeanDebug

#cheatsheet
-- InfoView shows:
-- Symbol  Input       Meaning
-- ──────  ──────────  ──────────────────────────
-- →       \to         function type, implication
-- ∘       \o          function composition
-- ·       \.          placeholder / function composition
-- ...
```

## How it works

1. `#debug` wraps the command, elaborates it, and captures error messages
2. Builds a JSON payload with diagnostics and source context
3. Calls `curl` against the Claude API via `IO.Process.output`
4. Parses the JSON response (skips thinking blocks, extracts text)
5. The result appears in InfoView via `logInfo`
