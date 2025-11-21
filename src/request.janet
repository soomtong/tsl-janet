``Module for LLM API requests with retry logic.

This module provides:
- HTTP requests using joyframework/http
- Multi-vendor LLM API requests (via vendor.janet)
- Exponential backoff retry logic for network/server errors
- Support for Groq, OpenAI, Anthropic, Gemini, and other vendors
``

(import spork/json)
(import http)
(import ./prompt)
(import ./vendor)

(defn handle-http-error
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
      (eprint "❌ Authentication Error (HTTP " status-code ")")
      (eprint "")
      (eprint "🔑 Your API key is invalid or expired.")
      (eprint "")
      (eprint "Please either:")
      (eprint "  1. Update your environment variable (e.g., GROQ_API_KEY)")
      (eprint "  2. Run configuration setup: tsl --init")
      (eprint "")
      nil)

    # Rate limit
    (= status-code 429)
    (do
      (eprint "")
      (eprint "⏱️  Rate Limit Error (HTTP 429)")
      (eprint "")
      (eprint "You have exceeded the API rate limit.")
      (eprint "Please wait a few minutes and try again.")
      (eprint "")
      nil)

    # Server errors (5xx)
    (and (>= status-code 500) (< status-code 600))
    (do
      (eprintf "")
      (eprintf "⚠️  Server Error (HTTP %d)" status-code)
      (eprintf "")
      (eprintf "The API server encountered an error.")
      (eprintf "🔄 This is usually temporary. Retrying...")
      (eprintf "")
      :retry)

    # Other errors
    (do
      (eprintf "")
      (eprintf "❌ HTTP Error %d" status-code)
      (eprintf "Response: %s" body)
      (eprintf "")
      nil)))

(defn make-llm-request
  ``Send a translation request to configured LLM vendor.

  Supports multiple vendors through vendor.janet configuration.
  Implements retry logic with exponential backoff for network and server errors.
  - Maximum 3 attempts
  - Exponential backoff: 1s, 2s, 4s
  - Retries only on network errors and 5xx status codes
  - Does not retry on 401/403/429 errors

  Arguments:
  - text: The text string to translate
  - api-key: API key for authentication
  - source-lang: Source language
  - target-lang: Target language
  - temperature: Temperature for generation (0.0-2.0)
  - vendor: Vendor name (string or keyword, e.g., "groq", :openai)
  - model: Model name (e.g., "groq/compound-mini", "gpt-4o-mini")
  - persona: Optional persona keyword (default: :default)

  Returns:
  The translated text as a string, or nil if the request fails.

  Example:
    (make-llm-request "Hello" "key" "English" "Korean" 0.3 "groq" "groq/compound-mini")
    (make-llm-request "Hello" "key" "English" "Korean" 0.3 :anthropic "claude-4-5-haiku-20241022")
  ``
  [text api-key source-lang target-lang temperature vendor model &opt persona]

  # Validate and build messages using prompt module
  (def validated-temp (prompt/validate-temperature temperature))
  (def messages (prompt/build-messages text source-lang target-lang persona))

  # Get vendor configuration
  (def vendor-config (vendor/get-vendor-config vendor))

  # Build URL and headers using vendor config
  (def url (vendor/build-url vendor-config model api-key))
  (def headers (vendor/build-headers vendor-config api-key))

  # Build request body in vendor-specific format
  (def payload (vendor/build-request-body vendor-config model messages validated-temp))

  # Encode to JSON
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
      (eprintf "🔄 Retry attempt %d/%d (waiting %d second%s)..."
               attempt max-attempts backoff-seconds
               (if (= backoff-seconds 1) "" "s"))
      (os/sleep backoff-seconds))

    # Make HTTP POST request using joyframework/http
    (def response
      (try
        (http/post url json-body :headers headers)
        ([err]
          (eprint "")
          (eprint "🌐 Network Error:")
          (eprint err)
          (eprint "")
          (if (< attempt max-attempts)
            (eprint "🔄 Retrying...")
            (eprint "❌ Maximum retry attempts reached."))
          nil)))

    # Handle response
    (when response
      (def status-code (get response :status))
      (def body (get response :body))

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
                (eprintf "❌ API error: %s" (get error :message))
                (eprintf "")
                (set should-retry false)
                nil)
              (do
                # Use vendor-specific response parsing
                (set result (vendor/parse-response vendor-config parsed))
                (set should-retry false)
                result)))
          ([err]
            (eprint "")
            (eprint "❌ Failed to parse API response: " err)
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
            (set should-retry false))))))

  result)
