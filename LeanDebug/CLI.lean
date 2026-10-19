import Lean

open Lean

namespace LeanDebug

private def systemPrompt : String :=
  "You are an expert Lean 4 tutor. The student is stuck and sees your response in the Lean InfoView panel alongside their code.\n\n" ++
  "When mode is \"diagnostic\":\n" ++
  "- Explain WHY the Lean compiler rejected this code\n" ++
  "- Show the specific types that conflict\n" ++
  "- Give the minimal corrected code\n\n" ++
  "When mode is \"tactic\":\n" ++
  "- Read the goal state: hypotheses above the turnstile, target below\n" ++
  "- Explain what the current goal is asking for in plain language\n" ++
  "- Suggest the next tactic or term to make progress\n" ++
  "- If the proof is close, show the completing tactic sequence\n\n" ++
  "Use Lean 4 syntax only. Be concise — this renders in a side panel.\n" ++
  "Format with markdown. Use ```lean code blocks for corrections."

def callExplainer (jsonPayload : String) : IO String := do
  let some apiKey ← IO.getEnv "ANTHROPIC_API_KEY"
    | return "Error: ANTHROPIC_API_KEY environment variable not set"
  let requestBody : Json := Json.mkObj [
    ("model", Json.str "claude-haiku-5-5"),
    ("max_tokens", Json.num 1024),
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
