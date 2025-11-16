#!/usr/bin/env janet

(import spork/json)
(import spork/http)

(defn parse-args
  ``Parse command line arguments with flags.

  Supports:
  - --source, -s: Source language (default: Korean)
  - --target, -t: Target language (default: English)
  - First positional argument: text to translate

  Returns:
  A struct with :text, :source, and :target keys.
  ``
  [args]

  (var text nil)
  (var source "Korean")
  (var target "English")
  (var i 0)

  (while (< i (length args))
    (def arg (get args i))
    (cond
      # Source language flags
      (or (= arg "--source") (= arg "-s"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set source (get args i))))

      # Target language flags
      (or (= arg "--target") (= arg "-t"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set target (get args i))))

      # Positional argument (text)
      (nil? text)
      (set text arg)

      # Unknown flag or extra argument
      (string/has-prefix? "--" arg)
      (do
        (eprintf "Unknown flag: %s" arg)
        (os/exit 1)))

    (set i (+ i 1)))

  {:text text :source source :target target})

(defn make-groq-request
  ``Send a translation request to Groq API using the compound-mini model.

  Arguments:
  - text: The text string to translate
  - api-key: Groq API key for authentication
  - source-lang: Source language (default: "Korean")
  - target-lang: Target language (default: "English")

  Returns:
  The translated text as a string, or nil if the request fails.

  Example:
    (make-groq-request "Hello world" "your-api-key" "English" "Korean")
  ``
  [text api-key source-lang target-lang]

  # Construct API payload with explicit source and target
  (def prompt (string "Translate from " source-lang " to " target-lang ": " text))
  (def payload
    {:model "compound-mini"
     :messages [{:role "user"
                 :content prompt}]})

  # Encode to JSON
  (def json-body (json/encode payload))

  # Make HTTP POST request
  (def response
    (try
      (http/request "POST" "https://api.groq.com/openai/v1/chat/completions"
        :body json-body
        :headers {"Content-Type" "application/json"
                  "Authorization" (string "Bearer " api-key)})
      ([err]
        (eprint "HTTP request failed: " err)
        nil)))

  # Handle response
  (when response
    (if (= (response :status) 200)
      (do
        (def body (http/read-body response))
        (def parsed (json/decode body true))
        (get-in parsed [:choices 0 :message :content]))
      (do
        (eprintf "API error: HTTP %d - %s" (response :status) (response :message))
        nil))))

(defn print-usage
  ``Print usage information.``
  []

  (eprint "Usage: janet src/main.janet <text> [options]")
  (eprint "")
  (eprint "Options:")
  (eprint "  -s, --source <lang>   Source language (default: Korean)")
  (eprint "  -t, --target <lang>   Target language (default: English)")
  (eprint "")
  (eprint "Examples:")
  (eprint "  janet src/main.janet \"안녕하세요\"")
  (eprint "  janet src/main.janet \"안녕하세요\" --target English")
  (eprint "  janet src/main.janet \"Hello\" --source English --target Korean")
  (eprint "  janet src/main.janet \"Bonjour\" -s French -t Korean"))

(defn main
  ``CLI entry point for the translation tool.

  Arguments:
  - args: Command line arguments passed to the script

  Supports flags:
  - --source, -s: Source language (default: Korean)
  - --target, -t: Target language (default: English)

  Requires GROQ_API_KEY environment variable to be set.
  ``
  [& args]

  # Check for API key
  (def api-key (os/getenv "GROQ_API_KEY"))
  (unless api-key
    (eprint "Error: GROQ_API_KEY environment variable is not set.")
    (eprint "Please set it with: export GROQ_API_KEY='your-api-key'")
    (os/exit 1))

  # Parse arguments
  (def parsed (parse-args args))
  (def text (parsed :text))
  (def source (parsed :source))
  (def target (parsed :target))

  # Validate text
  (unless text
    (eprint "Error: No text provided to translate.")
    (eprint "")
    (print-usage)
    (os/exit 1))

  # Execute translation
  (print "Translating from " source " to " target "...")
  (def result (make-groq-request text api-key source target))

  (if result
    (do
      (print "")
      (print "Translation:")
      (print result))
    (do
      (eprint "Translation failed.")
      (os/exit 1))))
