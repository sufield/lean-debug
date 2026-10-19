package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

type Diagnostic struct {
	Line     int    `json:"line"`
	Column   int    `json:"column"`
	Severity string `json:"severity"`
	Message  string `json:"message"`
}

type Payload struct {
	Mode          string       `json:"mode"`
	FilePath      string       `json:"file_path"`
	Diagnostics   []Diagnostic `json:"diagnostics"`
	GoalState     *string      `json:"goal_state"`
	SourceContext string       `json:"source_context"`
}

type claudeRequest struct {
	Model     string          `json:"model"`
	MaxTokens int             `json:"max_tokens"`
	System    string          `json:"system"`
	Messages  []claudeMessage `json:"messages"`
}

type claudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

const systemPrompt = `You are an expert Lean 4 tutor. The student is stuck and sees your response in the Lean InfoView panel alongside their code.

When mode is "diagnostic":
- Explain WHY the Lean compiler rejected this code
- Show the specific types that conflict
- Give the minimal corrected code

When mode is "tactic":
- Read the goal state: hypotheses above the turnstile, target below
- Explain what the current goal is asking for in plain language
- Suggest the next tactic or term to make progress
- If the proof is close, show the completing tactic sequence

Use Lean 4 syntax only. Be concise — this renders in a side panel.
Format with markdown. Use ` + "```lean" + ` code blocks for corrections.`

func main() {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "ANTHROPIC_API_KEY not set")
		os.Exit(1)
	}

	input, err := io.ReadAll(os.Stdin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "read stdin: %v\n", err)
		os.Exit(1)
	}

	var payload Payload
	if err := json.Unmarshal(input, &payload); err != nil {
		fmt.Fprintf(os.Stderr, "parse JSON: %v\n", err)
		os.Exit(1)
	}

	userContent, _ := json.Marshal(payload)

	reqBody, _ := json.Marshal(claudeRequest{
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 1024,
		System:    systemPrompt,
		Messages: []claudeMessage{
			{Role: "user", Content: string(userContent)},
		},
	})

	req, _ := http.NewRequest("POST", "https://api.anthropic.com/v1/messages", bytes.NewReader(reqBody))
	req.Header.Set("x-api-key", apiKey)
	req.Header.Set("anthropic-version", "2023-06-01")
	req.Header.Set("content-type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Fprintf(os.Stderr, "API request: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		fmt.Fprintf(os.Stderr, "API error %d: %s\n", resp.StatusCode, body)
		os.Exit(1)
	}

	var result struct {
		Content []struct {
			Text string `json:"text"`
		} `json:"content"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		fmt.Fprintf(os.Stderr, "parse response: %v\n", err)
		os.Exit(1)
	}
	if len(result.Content) == 0 {
		fmt.Fprintln(os.Stderr, "empty response from API")
		os.Exit(1)
	}

	fmt.Print(result.Content[0].Text)
}
