import Lean
import LeanDebug.Context
import LeanDebug.CLI

open Lean Elab Tactic Meta

namespace LeanDebug

elab "debug" : tactic => withMainContext do
  let goal ← getMainGoal
  let goalFmt ← ppGoal goal
  let goalStr := toString goalFmt
  let fileMap ← getFileMap
  let fileName ← getFileName
  let pos := (← getRef).getPos?.getD 0
  let line := fileMap.toPosition pos |>.line
  let sourceCtx := extractContext fileMap line 10
  let coreSt ← getThe Core.State
  let msgs := coreSt.messages.toList
  let diags ← gatherDiagnostics fileMap msgs
  let payload := buildPayload "tactic" diags (some goalStr) sourceCtx fileName
  let result ← callExplainer payload
  logInfo m!"{result}"

end LeanDebug
