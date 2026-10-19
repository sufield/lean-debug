import Lean

open Lean

namespace LeanDebug

private def systemPrompt : String :=
  "You are an expert Lean 4 tutor. Output renders in the Lean InfoView side panel.\n\n" ++
  "ALWAYS lead with the corrected code in a ```lean block, then explain.\n\n" ++
  "When mode is \"diagnostic\":\n" ++
  "1. Show the FIXED version of the code first\n" ++
  "2. Then explain what was wrong in 2-3 sentences\n" ++
  "Common pitfalls to check: simp loops (lemma rewrites back and forth), " ++
  "universe issues, missing imports, omega vs simp, structural vs well-founded recursion, " ++
  "type class instance resolution failures.\n" ++
  "If compiler_errors says \"Lean may report errors after elaboration\", " ++
  "you must analyze the source code carefully for these pitfalls.\n\n" ++
  "When mode is \"tactic\":\n" ++
  "1. Show the completing tactic sequence first\n" ++
  "2. Then explain the goal state briefly\n\n" ++
  "Use Lean 4 syntax only. Be concise."

def callExplainer (jsonPayload : String) : IO String := do
  let some apiKey ← IO.getEnv "ANTHROPIC_API_KEY"
    | return "Error: ANTHROPIC_API_KEY environment variable not set"
  let requestBody : Json := Json.mkObj [
    ("model", Json.str "claude-haiku-5-5"),
    ("max_tokens", Json.num 2048),
    ("system", Json.str systemPrompt),
    ("messages", Json.arr #[Json.mkObj [
      ("role", Json.str "user"),
      ("content", Json.str jsonPayload)
    ]])
  ]
  let workspaceId ← IO.getEnv "ANTHROPIC_WORKSPACE_ID"
  let mut args := #[
    "-s",
    "https://api.anthropic.com/v1/messages",
    "-H", s!"x-api-key: {apiKey}",
    "-H", "anthropic-version: 2023-06-01",
    "-H", "content-type: application/json"
  ]
  if let some wsId := workspaceId then
    args := args ++ #["-H", s!"anthropic-workspace-id: {wsId}"]
  args := args ++ #["-d", requestBody.compress]
  let result ← IO.Process.output { cmd := "curl", args := args }
  if result.exitCode != 0 then
    return s!"curl failed (exit {result.exitCode}): {result.stderr}"
  match Json.parse result.stdout with
  | .error e => return s!"JSON parse error: {e}"
  | .ok json =>
    match json.getObjValAs? (Array Json) "content" with
    | .error _ => return s!"Unexpected API response: {result.stdout}"
    | .ok content =>
      let textBlock := content.find? fun block =>
        match block.getObjValAs? String "type" with
        | .ok t => t == "text"
        | .error _ => false
      match textBlock with
      | some block =>
        match block.getObjValAs? String "text" with
        | .ok text => return text
        | .error _ => return s!"No text in response: {result.stdout}"
      | none => return s!"No text block in response: {result.stdout}"

end LeanDebug
