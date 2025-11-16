#!/usr/bin/env janet

(import spork/json)
(import spork/http)
(import ./prompt)

(defn parse-args
  ``Parse command line arguments with flags.

  Supports:
  - --source, -s: Source language (default: Korean)
  - --target, -t: Target language (default: English)
  - --temperature, -T: Temperature for generation (default: 0.3)
  - First positional argument: text to translate

  Returns:
  A struct with :text, :source, :target, and :temperature keys.
  ``
  [args]

  (var text nil)
  (var source "Korean")
  (var target "English")
  (var temperature prompt/DEFAULT_TEMPERATURE)
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

      # Temperature flag
      (or (= arg "--temperature") (= arg "-T"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (def temp-str (get args i))
          (def parsed-temp (scan-number temp-str))
          (when parsed-temp
            (set temperature parsed-temp))))

      # Positional argument (text)
      (nil? text)
      (set text arg)

      # Unknown flag or extra argument
      (string/has-prefix? "--" arg)
      (do
        (eprintf "Unknown flag: %s" arg)
        (os/exit 1)))

    (set i (+ i 1)))

  {:text text :source source :target target :temperature temperature})

(defn make-groq-request
  ``Send a translation request to Groq API using the compound-mini model.

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
    {:model "compound-mini"
     :messages messages
     :temperature validated-temp})

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
  (eprint "  -s, --source <lang>      Source language (default: Korean)")
  (eprint "  -t, --target <lang>      Target language (default: English)")
  (eprint "  -T, --temperature <num>  Temperature 0.0-2.0 (default: 0.3)")
  (eprint "")
  (eprint "Examples:")
  (eprint "  janet src/main.janet \"안녕하세요\"")
  (eprint "  janet src/main.janet \"안녕하세요\" --target English")
  (eprint "  janet src/main.janet \"Hello\" -s English -t Korean")
  (eprint "  janet src/main.janet \"Bonjour\" -s French -t Korean -T 0.5"))

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
  (def temperature (parsed :temperature))

  # Validate text
  (unless text
    (eprint "Error: No text provided to translate.")
    (eprint "")
    (print-usage)
    (os/exit 1))

  # Execute translation
  (print "Translating from " source " to " target "...")
  (print "Temperature: " temperature)
  (def result (make-groq-request text api-key source target temperature))

  (if result
    (do
      (print "")
      (print "Translation:")
      (print result))
    (do
      (eprint "Translation failed.")
      (os/exit 1))))
