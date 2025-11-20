#!/usr/bin/env janet

(import spork/json)
(import spork/sh)
(import ./prompt)
(import ./config)
(import ./cli)

(defn make-groq-request
  ``Send a translation request to Groq API using the groq/compound-mini model.

  Arguments:
  - text: The text string to translate
  - api-key: Groq API key for authentication
  - source-lang: Source language
  - target-lang: Target language
  - temperature: Temperature for generation (0.0-2.0)

  Returns:
  The translated text as a string, or nil if the request fails.

  Example:
    (make-groq-request "Hello world" "your-api-key" "English" "Korean" 0.3)
  ``
  [text api-key source-lang target-lang temperature]

  # Validate and build messages using prompt module
  (def validated-temp (prompt/validate-temperature temperature))
  (def messages (prompt/build-messages text source-lang target-lang))

  # Construct API payload
  (def payload
    {:model "groq/compound-mini"
     :messages messages
     :temperature validated-temp})

  # Encode to JSON and ensure it's a string
  (def json-body (string (json/encode payload)))

  # Make HTTP POST request using curl via spork/sh
  (def response-body
    (try
      (sh/exec-slurp
        "curl" "-s" "-X" "POST"
        "https://api.groq.com/openai/v1/chat/completions"
        "-H" "Content-Type: application/json"
        "-H" (string "Authorization: Bearer " api-key)
        "-d" json-body)
      ([err]
        (eprint "HTTP request failed: " err)
        nil)))

  # Handle response
  (when response-body
    (try
      (do
        (def parsed (json/decode response-body true))
        (if-let [error (get parsed :error)]
          (do
            (eprintf "API error: %s" (get error :message))
            nil)
          (get-in parsed [:choices 0 :message :content])))
      ([err]
        (eprint "Failed to parse API response: " err)
        (eprint "Response: " response-body)
        nil))))

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
      # Running with `janet src/main.janet ...`, slice first 2
      (tuple/slice all-args 2)
      # Running compiled binary `./tsl ...`, slice first 1
      (tuple/slice all-args 1)))

  # Load config and parse args
  (def conf (config/load-config))

  # Check if --init flag is present (early check before full parsing)
  (def has-init-flag (some |(= $ "--init") actual-args))

  # If --init is requested, show placeholder and exit
  (when has-init-flag
    (print "")
    (print "Initialization wizard will be implemented in Phase 2.")
    (print "")
    (print "Current default configuration:")
    (pp conf)
    (print "")
    (print "Configuration file location:")
    (def config-path
      (if-let [xdg-config (os/getenv "XDG_CONFIG_HOME")]
        (string xdg-config "/tsl/config.json")
        (string (os/getenv "HOME") "/.config/tsl/config.json")))
    (print config-path)
    (os/exit 0))

  # If config doesn't exist, suggest initialization
  (unless (config/config-exists?)
    (cli/print-init-suggestion))

  (def parsed (cli/parse-args actual-args conf))

  (def text (parsed :text))
  (def source (parsed :source))
  (def target (parsed :target))
  (def temperature (parsed :temperature))
  (def copy (parsed :copy))
  (def api-key (parsed :api-key))

  # Validate API Key
  (unless api-key
    (eprint "")
    (eprint "Error: No API Key found.")
    (eprint "")
    (eprint "Please either:")
    (eprint "  1. Set GROQ_API_KEY environment variable:")
    (eprint "     export GROQ_API_KEY=\"your-key-here\"")
    (eprint "  2. Run configuration setup:")
    (eprint "     janet src/main.janet --init")
    (eprint "")
    (os/exit 1))

  # Validate text
  (unless text
    (eprint "Error: No text provided to translate.")
    (eprint "")
    (cli/print-usage)
    (os/exit 1))

  # Execute translation
  (print "Translating from " source " to " target "...")
  # Only print temp if it's different from default to reduce noise, or always print? Existing behavior printed it.
  (print "Temperature: " temperature)
  
  (def result (make-groq-request text api-key source target temperature))

  (if result
    (do
      (print "")
      (print "Translation:")
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
            (print "📋 Copied to clipboard"))
          ([err]
            # Silently ignore if pbcopy is not available
            nil))))
    (do
      (eprint "Translation failed.")
      (os/exit 1))))
