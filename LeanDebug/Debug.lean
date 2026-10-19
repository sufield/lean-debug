import Lean
import LeanDebug.Context
import LeanDebug.CLI

open Lean Elab Command

namespace LeanDebug

elab "#debug " cmd:command : command => do
  let prevMsgs := (← get).messages
  modify fun st => { st with messages := {} }
  elabCommand cmd
  let newMsgs := (← get).messages
  modify fun st => { st with messages := prevMsgs ++ newMsgs }
  let fileMap ← getFileMap
  let fileName ← getFileName
  let errorMsgs := newMsgs.toArray.filter fun msg =>
    msg.severity == .error || msg.severity == .warning
  if errorMsgs.isEmpty then
    logInfo "No diagnostics from this command."
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
  let result ← callExplainer payload
  logInfo m!"{result}"

end LeanDebug
