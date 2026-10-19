import Lean
import LeanDebug.Context
import LeanDebug.CLI

open Lean Elab Command

namespace LeanDebug

elab "#debug" : command => do
  let st ← get
  let fileMap ← getFileMap
  let fileName ← getFileName
  let msgs := st.messages.toList
  let diags ← gatherDiagnostics fileMap msgs
  if diags.isEmpty then
    logInfo "No diagnostics found above this point."
    return
  let pos := (← getRef).getPos?.getD 0
  let line := fileMap.toPosition pos |>.line
  let ctx := extractContext fileMap line 10
  let payload := buildPayload "diagnostic" diags none ctx fileName
  let result ← callExplainer payload
  logInfo m!"{result}"

end LeanDebug
