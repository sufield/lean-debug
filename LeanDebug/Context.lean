import Lean

namespace LeanDebug

structure DiagnosticJson where
  line : Nat
  column : Nat
  severity : String
  message : String

/-- Extract lines [start-radius .. start+radius] from the source. -/
def extractContext (fileMap : Lean.FileMap) (line : Nat) (radius : Nat) : String :=
  let lines := fileMap.source.splitOn "\n"
  let lo := if line > radius then line - radius else 0
  let hi := min (line + radius) lines.length
  let slice := lines.toArray[lo:hi]
  "\n".intercalate slice.toList

/-- Gather error/warning diagnostics from the message log. -/
def gatherDiagnostics (_fileMap : Lean.FileMap) (msgs : List Lean.Message) :
    IO (Array DiagnosticJson) := do
  let mut result := #[]
  for msg in msgs do
    if msg.severity == .error || msg.severity == .warning then
      let text ← msg.data.toString
      let sev := if msg.severity == .error then "error" else "warning"
      result := result.push {
        line := msg.pos.line
        column := msg.pos.column
        severity := sev
        message := text
      }
  return result

/-- Build the JSON payload string for the Go CLI. -/
def buildPayload (mode : String) (diags : Array DiagnosticJson)
    (goalState : Option String) (sourceCtx : String) (filePath : String) :
    String :=
  let diagArr := diags.toList.map fun d =>
    s!"\{\"line\":{d.line},\"column\":{d.column},\"severity\":\"{d.severity}\",\"message\":{Lean.Json.renderString d.message}}"
  let diagStr := ",".intercalate diagArr
  let goalStr := match goalState with
    | some g => s!"\"goal_state\":{Lean.Json.renderString g}"
    | none   => "\"goal_state\":null"
  s!"\{\"mode\":\"{mode}\",\"file_path\":{Lean.Json.renderString filePath},\"diagnostics\":[{diagStr}],{goalStr},\"source_context\":{Lean.Json.renderString sourceCtx}}"

end LeanDebug
