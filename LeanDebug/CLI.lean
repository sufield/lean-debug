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
    ("model", Json.str "claude-sonnet-4-20250514"),
    ("max_tokens", Json.num 1024),
    ("system", Json.str systemPrompt),
    ("messages", Json.arr #[Json.mkObj [
      ("role", Json.str "user"),
      ("content", Json.str jsonPayload)
    ]])
  ]
  let result ← IO.Process.output {
    cmd := "curl"
    args := #[
      "-s",
      "https://api.anthropic.com/v1/messages",
      "-H", s!"x-api-key: {apiKey}",
      "-H", "anthropic-version: 2023-06-01",
      "-H", "content-type: application/json",
      "-d", requestBody.compress
    ]
  }
  if result.exitCode != 0 then
    return s!"curl failed (exit {result.exitCode}): {result.stderr}"
  match Json.parse result.stdout with
  | .error e => return s!"JSON parse error: {e}"
  | .ok json =>
    match json.getObjValAs? (Array Json) "content" with
    | .error _ => return s!"Unexpected API response: {result.stdout}"
    | .ok content =>
      if h : content.size > 0 then
        match content[0].getObjValAs? String "text" with
        | .ok text => return text
        | .error _ => return s!"No text in response: {result.stdout}"
      else
        return "Empty response from API"

end LeanDebug
