``Module for CLI help and configuration display functions.

This module provides:
- Configuration display (show-config)
- Prompt template display (show-prompt)
- Persona information display (show-persona)
``

(import ./prompt)

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
