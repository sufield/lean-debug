import Lean

namespace LeanDebug

/-- Shell out to the `lean-explain` binary with a JSON payload on stdin.
    Returns the explanation or an error string. -/
def callExplainer (jsonPayload : String) : IO String := do
  let child ← IO.Process.spawn {
    cmd := "lean-explain"
    stdin := .piped
    stdout := .piped
    stderr := .piped
  }
  let stdin := child.stdin
  stdin.putStr jsonPayload
  stdin.flush
  let stdout ← IO.asTask child.stdout.readToEnd
  let stderr ← IO.asTask child.stderr.readToEnd
  let exitCode ← child.wait
  let output ← IO.ofExcept stdout.get
  let errors ← IO.ofExcept stderr.get
  if exitCode != 0 then
    return s!"lean-explain failed (exit {exitCode}): {errors}"
  return output

end LeanDebug
