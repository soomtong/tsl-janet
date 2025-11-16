#!/usr/bin/env janet

(import spork/json)
(import spork/http)

(defn make-groq-request
  ``Send a translation request to Groq API using the compound-mini model.

  Arguments:
  - text: The text string to translate
  - api-key: Groq API key for authentication
  - target-lang: Target language for translation (default: "Korean")

  Returns:
  The translated text as a string, or nil if the request fails.

  Example:
    (make-groq-request "Hello world" "your-api-key" "Korean")
  ``
  [text api-key &opt target-lang]

  (default target-lang "Korean")

  # Construct API payload
  (def prompt (string "Translate the following text to " target-lang ": " text))
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

(defn validate-args
  ``Validate command line arguments.

  Arguments:
  - args: Array of command line arguments

  Returns:
  The joined text string if valid, or nil if invalid.
  ``
  [args]

  (when (< (length args) 1)
    (eprint "Usage: janet poc1.janet <text-to-translate> [target-language]")
    (eprint "")
    (eprint "Example:")
    (eprint "  janet poc1.janet \"Hello world\" Korean")
    (eprint "  janet poc1.janet \"Bonjour\" English")
    (os/exit 1))

  args)

(defn main
  ``CLI entry point for the translation tool.

  Arguments:
  - args: Command line arguments passed to the script

  The first argument is the text to translate.
  The optional second argument is the target language (default: Korean).
  Requires GROQ_API_KEY environment variable to be set.
  ``
  [& args]

  # Check for API key
  (def api-key (os/getenv "GROQ_API_KEY"))
  (unless api-key
    (eprint "Error: GROQ_API_KEY environment variable is not set.")
    (eprint "Please set it with: export GROQ_API_KEY='your-api-key'")
    (os/exit 1))

  # Validate and parse arguments
  (validate-args args)

  (def text (get args 0))
  (def target-lang (get args 1 "Korean"))

  # Execute translation
  (print "Translating to " target-lang "...")
  (def result (make-groq-request text api-key target-lang))

  (if result
    (do
      (print "")
      (print "Translation:")
      (print result))
    (do
      (eprint "Translation failed.")
      (os/exit 1))))
