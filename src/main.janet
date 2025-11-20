#!/usr/bin/env janet

(import spork/json)
(import spork/sh)
(import ./prompt)
(import ./config)
(import ./cli)
(import ./init :as init-mod)

(defn- parse-http-response
  ``Parse HTTP response with status code.

  Expects response in format: "BODY\nSTATUS_CODE"

  Arguments:
  - response: Full HTTP response string

  Returns:
  Struct with :body and :status-code, or nil on parse failure
  ``
  [response]

  (def lines (string/split "\n" response))
  (when (>= (length lines) 2)
    (def status-line (last lines))
    (def status-code (scan-number status-line))
    (def body (string/join (slice lines 0 -2) "\n"))
    {:body body :status-code status-code}))

(defn- handle-http-error
  ``Handle HTTP error with appropriate message.

  Arguments:
  - status-code: HTTP status code
  - body: Response body (may contain error details)

  Returns:
  Error message string
  ``
  [status-code body]

  (cond
    # Authentication errors
    (or (= status-code 401) (= status-code 403))
    (do
      (eprint "")
      (eprint "Authentication Error (HTTP " status-code ")")
      (eprint "")
      (eprint "Your API key is invalid or expired.")
      (eprint "")
      (eprint "Please either:")
      (eprint "  1. Update your environment variable (e.g., GROQ_API_KEY)")
      (eprint "  2. Run configuration setup: janet src/main.janet --init")
      (eprint "")
      nil)

    # Rate limit
    (= status-code 429)
    (do
      (eprint "")
      (eprint "Rate Limit Error (HTTP 429)")
      (eprint "")
      (eprint "You have exceeded the API rate limit.")
      (eprint "Please wait a few minutes and try again.")
      (eprint "")
      nil)

    # Server errors (5xx)
    (and (>= status-code 500) (< status-code 600))
    (do
      (eprintf "")
      (eprintf "Server Error (HTTP %d)" status-code)
      (eprintf "")
      (eprintf "The API server encountered an error.")
      (eprintf "This is usually temporary. Retrying...")
      (eprintf "")
      :retry)

    # Other errors
    (do
      (eprintf "")
      (eprintf "HTTP Error %d" status-code)
      (eprintf "Response: %s" body)
      (eprintf "")
      nil)))

(defn make-groq-request
  ``Send a translation request to Groq API using the groq/compound-mini model.

  Implements retry logic with exponential backoff for network and server errors.
  - Maximum 3 attempts
  - Exponential backoff: 1s, 2s, 4s
  - Retries only on network errors and 5xx status codes
  - Does not retry on 401/403/429 errors

  Arguments:
  - text: The text string to translate
  - api-key: Groq API key for authentication
  - source-lang: Source language
  - target-lang: Target language
  - temperature: Temperature for generation (0.0-2.0)
  - persona: Optional persona keyword (default: :default)

  Returns:
  The translated text as a string, or nil if the request fails.

  Example:
    (make-groq-request "Hello world" "your-api-key" "English" "Korean" 0.3 "programming")
  ``
  [text api-key source-lang target-lang temperature &opt persona]

  # Validate and build messages using prompt module
  (def validated-temp (prompt/validate-temperature temperature))
  (def messages (prompt/build-messages text source-lang target-lang persona))

  # Construct API payload
  (def payload
    {:model "groq/compound-mini"
     :messages messages
     :temperature validated-temp})

  # Encode to JSON and ensure it's a string
  (def json-body (string (json/encode payload)))

  # Retry loop with exponential backoff
  (def max-attempts 3)
  (var attempt 0)
  (var result nil)
  (var should-retry true)

  (while (and should-retry (< attempt max-attempts))
    (++ attempt)

    # Show retry message
    (when (> attempt 1)
      (def backoff-seconds (math/pow 2 (- attempt 2)))
      (eprintf "Retry attempt %d/%d (waiting %d second%s)..."
               attempt max-attempts backoff-seconds
               (if (= backoff-seconds 1) "" "s"))
      (os/sleep backoff-seconds))

    # Make HTTP POST request using curl via spork/sh
    (def response
      (try
        (sh/exec-slurp
          "curl" "-s" "-X" "POST"
          "-w" "\n%{http_code}"
          "https://api.groq.com/openai/v1/chat/completions"
          "-H" "Content-Type: application/json"
          "-H" (string "Authorization: Bearer " api-key)
          "-d" json-body)
        ([err]
          (eprint "")
          (eprint "Network Error:")
          (eprint err)
          (eprint "")
          (if (< attempt max-attempts)
            (eprint "Retrying...")
            (eprint "Maximum retry attempts reached."))
          nil)))

    # Handle response
    (when response
      (def parsed-response (parse-http-response response))

      (if parsed-response
        (do
          (def status-code (get parsed-response :status-code))
          (def body (get parsed-response :body))

          # Check status code
          (cond
            # Success
            (= status-code 200)
            (try
              (do
                (def parsed (json/decode body true))
                (if-let [error (get parsed :error)]
                  (do
                    (eprintf "")
                    (eprintf "API error: %s" (get error :message))
                    (eprintf "")
                    (set should-retry false)
                    nil)
                  (do
                    (set result (get-in parsed [:choices 0 :message :content]))
                    (set should-retry false)
                    result)))
              ([err]
                (eprint "")
                (eprint "Failed to parse API response: " err)
                (eprint "Response body: " body)
                (eprint "")
                (set should-retry false)
                nil))

            # Handle various HTTP errors
            (do
              (def error-result (handle-http-error status-code body))
              (if (= error-result :retry)
                # Server error, continue retry loop
                (set should-retry (< attempt max-attempts))
                # Other errors, stop retrying
                (set should-retry false)))))

        # Failed to parse response
        (do
          (eprint "Failed to parse HTTP response format")
          (set should-retry false)))))

  result)

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
    (show-config parsed)
    (os/exit 0))

  (when (get parsed :show-prompt)
    (show-prompt parsed)
    (os/exit 0))

  (when (get parsed :show-persona)
    (show-persona parsed)
    (os/exit 0))

  (def text (parsed :text))
  (def source (parsed :source))
  (def target (parsed :target))
  (def persona (parsed :persona))
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
  (print "Temperature: " temperature)
  (print "Persona: " persona)

  (def result (make-groq-request text api-key source target temperature persona))

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
