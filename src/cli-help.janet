``Module for CLI help and configuration display functions.

This module provides:
- Usage information (print-usage)
- Configuration display (show-config)
- Prompt template display (show-prompt)
- Persona information display (show-persona)
``

(import ./prompt)

(defn print-usage
  ``Print usage information.``
  []
  (eprint "Usage: tsl <text> [options]")
  (eprint "")
  (eprint "Options:")
  (eprint "  -s, --source <lang>      Source language (default: Korean)")
  (eprint "  -t, --target <lang>      Target language (default: English)")
  (eprint "  -T, --temperature <num>  Temperature 0.0-2.0 (default: 0.3)")
  (eprint "  -p, --persona <name>     Persona (default, programming, research, review)")
  (eprint "  -V, --vendor <vendor>    LLM vendor (groq, openai, anthropic, etc.)")
  (eprint "  -m, --model <model>      Model name")
  (eprint "  --no-copy                Disable automatic clipboard copy")
  (eprint "  --init                   Run configuration wizard")
  (eprint "  --show-config            Show current configuration")
  (eprint "  --show-prompt            Show current prompt template")
  (eprint "  --show-persona           Show current persona")
  (eprint "  -h, --help               Show this help message")
  (eprint "")
  (eprint "Examples:")
  (eprint "  tsl \"안녕하세요\"")
  (eprint "  tsl \"안녕하세요\" --target English")
  (eprint "  tsl \"Hello\" -s English -t Korean")
  (eprint "  tsl \"Bonjour\" -s French -t Korean -T 0.5")
  (eprint "  tsl \"코드 작성\" --persona programming")
  (eprint "  tsl \"Hello\" -V openai -m gpt-4o-mini")
  (eprint "  tsl \"Hello\" --vendor anthropic --model claude-4-5-haiku-20241022")
  (eprint "  tsl \"Hello\" --no-copy")
  (eprint "  tsl --init")
  (eprint "  tsl --show-config")
  (eprint "  tsl --show-prompt")
  (eprint "  tsl --show-persona"))

(defn show-config
  ``Display current configuration settings.

  Shows vendor, model, source language, target language, temperature, persona, and copy setting.
  API key is not displayed for security reasons.
  ``
  [parsed]
  (print "")
  (print "=== Current Configuration ===")
  (print "")
  (printf "Vendor:       %s" (or (get parsed :vendor) "groq"))
  (printf "Model:        %s" (or (get parsed :model) "groq/compound-mini"))
  (printf "Source:       %s" (or (get parsed :source) "Korean"))
  (printf "Target:       %s" (or (get parsed :target) "English"))
  (printf "Temperature:  %.1f" (or (get parsed :temperature) 0.3))
  (printf "Persona:      %s" (or (get parsed :persona) "default"))
  (printf "Clipboard:    %s" (if (get parsed :copy) "enabled" "disabled"))
  (print "")
  (print "Note: API key is not displayed for security reasons.")
  (print ""))

(defn show-prompt
  ``Display current prompt template.

  Shows the system prompt that will be used for translation requests.
  ``
  [parsed]
  (def persona-str (or (get parsed :persona) "default"))
  (def persona-key (prompt/validate-persona persona-str))
  (def prompt-text (prompt/get-system-prompt persona-key))

  (print "")
  (print "=== Current Prompt Template ===")
  (print "")
  (printf "Persona: %s" persona-str)
  (print "")
  (print prompt-text)
  (print ""))

(defn show-persona
  ``Display current persona information.

  Shows the current persona name, title, and description.
  ``
  [parsed]
  (def persona-str (or (get parsed :persona) "default"))
  (def persona-key (prompt/validate-persona persona-str))
  (def persona-title (get prompt/persona-titles persona-key))
  (def persona-desc (get prompt/persona-prompts persona-key))

  (print "")
  (print "=== Current Persona ===")
  (print "")
  (printf "Name:        %s" persona-str)
  (printf "Title:       %s" (or persona-title "Unknown"))
  (printf "Description: %s" (or persona-desc "No description"))
  (print "")
  (print "Available personas:")
  (each key (prompt/get-persona-list)
    (def title (get prompt/persona-titles key))
    (printf "  - %s (%s)" (string key) (or title "Unknown")))
  (print ""))
