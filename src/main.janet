#!/usr/bin/env janet

(import spork/sh)
(import ./prompt)
(import ./config)
(import ./cli)
(import ./cli-help)
(import ./vendor)
(import ./request)
(import ./init :as init-mod)

(defn main [& args]
  ``CLI entry point for the translation tool.

  Uses src/config.janet for configuration and src/cli.janet for argument parsing.
  ``
  # Get all command line args dynamically for consistency
  (def all-args (dyn :args))

  # Determine the actual arguments for parsing by slicing off the executable/script
  (def actual-args
    (if (and (> (length all-args) 1)
             (string/has-suffix? ".janet" (get all-args 1)))
      # Running with `tsl ...`, slice first 2
      (tuple/slice all-args 2)
      # Running compiled binary `./tsl ...`, slice first 1
      (tuple/slice all-args 1)))

  # Load config and parse args
  (def conf (config/load-config))

  # Check if --init flag is present (early check before full parsing)
  (def has-init-flag (some |(= $ "--init") actual-args))

  # If --init is requested, run initialization wizard
  (when has-init-flag
    (init-mod/run-init-wizard)
    (os/exit 0))

  # If config doesn't exist, suggest initialization
  (unless (config/config-exists?)
    (cli/print-init-suggestion))

  (def parsed (cli/parse-args actual-args conf))

  # Handle show flags (these don't require API key or text)
  (when (get parsed :show-config)
    (cli-help/show-config parsed)
    (os/exit 0))

  (when (get parsed :show-prompt)
    (cli-help/show-prompt parsed)
    (os/exit 0))

  (when (get parsed :show-persona)
    (cli-help/show-persona parsed)
    (os/exit 0))

  (when (get parsed :help)
    (cli-help/print-usage)
    (os/exit 0))

  (def text (parsed :text))
  (def source (parsed :source))
  (def target (parsed :target))
  (def persona (parsed :persona))
  (def temperature (parsed :temperature))
  (def vendor (parsed :vendor))
  (def model (parsed :model))
  (def api-key (parsed :api-key))
  (def copy (parsed :copy))

  # Validate API Key
  (unless api-key
    (eprint "")
    (eprint "❌  Error: No API Key found.")
    (eprint "")
    (eprint "Please either:")
    (eprint "  1. Set GROQ_API_KEY environment variable:")
    (eprint "     export GROQ_API_KEY=\"your-key-here\"")
    (eprint "  2. Run configuration setup:")
    (eprint "     tsl --init")
    (eprint "")
    (os/exit 1))

  # Validate text
  (unless text
    (eprint "❌  Error: No text provided to translate.")
    (eprint "")
    (cli-help/print-usage)
    (os/exit 1))

  # Execute translation
  (print "🌐  Translating from " source " to " target "...")
  (print "Vendor: " vendor)
  (print "Model: " model)
  (print "Temperature: " temperature)
  (print "Persona: " persona)

  (def result (request/make-llm-request text api-key source target temperature vendor model persona))

  (if result
    (do
      (print "")
      (print "✨ Translation:")
      (print result)

      # Copy to clipboard if enabled
      (when copy
        (try
          (do
            # Remove quotes and newlines
            (def without-quotes (string/replace-all "\"" "" result))
            (def clean-result (string/replace-all "\n" " " without-quotes))
            # Escape single quotes for shell
            (def escaped (string/replace-all "'" "'\"'\"'" clean-result))
            (sh/exec "sh" "-c" (string "printf '%s' '" escaped "' | pbcopy"))
            (print "📋  Copied to clipboard"))
          ([err]
            # Silently ignore if pbcopy is not available
            nil))))
    (do
      (eprint "❌ Translation failed.")
      (os/exit 1))))
