import Lean
import LeanDebug.Context
import LeanDebug.CLI

open Lean Elab Command

namespace LeanDebug

elab "#debug" : command => do
  let st ← get
  let allMsgs := st.messages.toArray
  let sevs := allMsgs.map fun m => match m.severity with
    | .error => "error"
    | .warning => "warning"
    | .information => "info"
  logInfo m!"[debug] total: {allMsgs.size}, severities: {sevs.toList}"
  let fileMap ← getFileMap
  let fileName ← getFileName
  let errorMsgs := allMsgs.filter fun msg =>
    msg.severity == .error || msg.severity == .warning
  if errorMsgs.isEmpty then
    logInfo "[debug] no error/warning messages found — nothing to explain."
    return
  let mut diagArr : Array DiagnosticJson := #[]
  for msg in errorMsgs do
    let fmt ← msg.data.format
    let text := fmt.pretty
    diagArr := diagArr.push {
      line := msg.pos.line
      column := msg.pos.column
      severity := if msg.severity == .error then "error" else "warning"
      message := text
    }
  let pos := (← getRef).getPos?.getD 0
  let line := fileMap.toPosition pos |>.line
  let ctx := extractContext fileMap line 20
  let payload := buildPayload "diagnostic" diagArr none ctx fileName
  logInfo m!"[debug] sending {diagArr.size} diagnostics to Claude..."
  let result ← callExplainer payload
  logInfo m!"{result}"

end LeanDebug
