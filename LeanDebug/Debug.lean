import Lean
import LeanDebug.Context
import LeanDebug.CLI

open Lean Elab Command

namespace LeanDebug

private def verbose : IO Bool := do
  let v ← IO.getEnv "LEAN_DEBUG_VERBOSE"
  return v.isSome

private def trace (s : String) : IO Unit := do
  if (← verbose) then
    let stderr ← IO.getStderr
    stderr.putStrLn s

syntax (name := debugCmd) "#debug" command : command

@[command_elab debugCmd]
def elabDebug : CommandElab := fun stx => do
  let cmd := stx[1]
  trace "[lean-debug] elaborating command..."
  try
    elabCommand cmd
  catch _ => pure ()
  let fileName ← getFileName
  let cmdSrc := cmd.reprint.getD s!"{cmd}"
  trace s!"[lean-debug] source extracted ({cmdSrc.length} chars)"
  let allMsgs := (← get).messages.toArray
  let errorMsgs := allMsgs.filter fun msg =>
    msg.severity == .error || msg.severity == .warning
  let mut errTexts : Array String := #[]
  for msg in errorMsgs do
    let fmt ← msg.data.format
    errTexts := errTexts.push fmt.pretty
  let errSection := if errTexts.isEmpty then
    "(Lean may report errors after elaboration — analyze the code for issues)"
  else
    String.intercalate "\n\n" errTexts.toList
  let payload := Json.mkObj [
    ("mode", Json.str "diagnostic"),
    ("file_path", Json.str fileName),
    ("source_code", Json.str cmdSrc),
    ("compiler_errors", Json.str errSection)
  ]
  trace "[lean-debug] calling Claude API..."
  let result ← callExplainer payload.compress
  trace s!"[lean-debug] response received ({result.length} chars)"
  logInfo m!"{result}"

end LeanDebug
