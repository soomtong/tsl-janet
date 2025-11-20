(import ../src/vendor)

(defn test-vendor-configs-exist []
  (print "\nTesting vendor configurations exist...")

  # Test that all expected vendors are defined
  (def expected-vendors
    [:groq :openai :deepseek :cerebras :openrouter :mistral :anthropic :gemini])

  (each vendor-key expected-vendors
    (def config (vendor/get-vendor-config vendor-key))
    (assert config (string/format "%s config should exist" vendor-key))
    (assert (get config :base-url) (string/format "%s should have base-url" vendor-key))
    (assert (get config :auth-type) (string/format "%s should have auth-type" vendor-key))
    (assert (get config :api-format) (string/format "%s should have api-format" vendor-key)))

  (print "Vendor configurations exist test passed!"))

(defn test-get-vendor-config []
  (print "\nTesting get-vendor-config function...")

  # Test with keyword
  (def groq-config (vendor/get-vendor-config :groq))
  (assert (= (get groq-config :base-url) "https://api.groq.com") "Groq URL should match")

  # Test with string
  (def openai-config (vendor/get-vendor-config "openai"))
  (assert (= (get openai-config :base-url) "https://api.openai.com") "OpenAI URL should match")

  # Test fallback to default (groq) for invalid vendor
  (def invalid-config (vendor/get-vendor-config :nonexistent))
  (assert (= (get invalid-config :base-url) "https://api.groq.com") "Should fallback to Groq")

  (print "get-vendor-config test passed!"))

(defn test-build-url []
  (print "\nTesting build-url function...")

  # Test OpenAI-compatible vendor
  (def groq-config (vendor/get-vendor-config :groq))
  (def groq-url (vendor/build-url groq-config "groq/compound-mini"))
  (assert (= groq-url "https://api.groq.com/openai/v1/chat/completions") "Groq URL should be correct")

  # Test Gemini with model in URL
  (def gemini-config (vendor/get-vendor-config :gemini))
  (def gemini-url (vendor/build-url gemini-config "gemini-2.0-flash-exp" "test-key"))
  (assert (string/find "gemini-2.0-flash-exp" gemini-url) "Gemini URL should contain model name")
  (assert (string/find "key=test-key" gemini-url) "Gemini URL should contain API key")

  # Test Anthropic
  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (def anthropic-url (vendor/build-url anthropic-config "claude-4-5-haiku-20241022"))
  (assert (= anthropic-url "https://api.anthropic.com/v1/messages") "Anthropic URL should be correct")

  (print "build-url test passed!"))

(defn test-build-headers []
  (print "\nTesting build-headers function...")

  # Test Bearer auth (Groq, OpenAI, etc.)
  (def groq-config (vendor/get-vendor-config :groq))
  (def groq-headers (vendor/build-headers groq-config "test-api-key"))
  (assert (= (get groq-headers "Content-Type") "application/json") "Should have Content-Type")
  (assert (= (get groq-headers "Authorization") "Bearer test-api-key") "Should have Bearer auth")

  # Test x-api-key auth (Anthropic)
  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (def anthropic-headers (vendor/build-headers anthropic-config "test-key"))
  (assert (= (get anthropic-headers "x-api-key") "test-key") "Should have x-api-key")
  (assert (= (get anthropic-headers "anthropic-version") "2023-06-01") "Should have anthropic-version")

  # Test query-param auth (Gemini) - should not add auth header
  (def gemini-config (vendor/get-vendor-config :gemini))
  (def gemini-headers (vendor/build-headers gemini-config "test-key"))
  (assert (nil? (get gemini-headers "Authorization")) "Gemini should not have Authorization header")
  (assert (nil? (get gemini-headers "x-api-key")) "Gemini should not have x-api-key header")

  (print "build-headers test passed!"))

(defn test-build-request-body-openai []
  (print "\nTesting build-request-body for OpenAI format...")

  (def groq-config (vendor/get-vendor-config :groq))
  (def messages
    @[{:role "system" :content "You are a translator"}
      {:role "user" :content "Hello"}])

  (def body (vendor/build-request-body groq-config "groq/compound-mini" messages 0.3))

  (assert (= (get body :model) "groq/compound-mini") "Should have model")
  (assert (= (get body :messages) messages) "Should have messages")
  (assert (= (get body :temperature) 0.3) "Should have temperature")

  (print "build-request-body OpenAI format test passed!"))

(defn test-build-request-body-anthropic []
  (print "\nTesting build-request-body for Anthropic format...")

  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (def messages
    @[{:role "system" :content "You are a translator"}
      {:role "user" :content "Hello"}])

  (def body (vendor/build-request-body anthropic-config "claude-4-5-haiku-20241022" messages 0.3))

  (assert (= (get body :model) "claude-4-5-haiku-20241022") "Should have model")
  (assert (= (get body :system) "You are a translator") "Should have system as top-level")
  (assert (= (get body :max_tokens) 4096) "Should have max_tokens")
  (assert (= (length (get body :messages)) 1) "Should have only user messages")
  (assert (= (get body :temperature) 0.3) "Should have temperature")

  (print "build-request-body Anthropic format test passed!"))

(defn test-build-request-body-gemini []
  (print "\nTesting build-request-body for Gemini format...")

  (def gemini-config (vendor/get-vendor-config :gemini))
  (def messages
    @[{:role "system" :content "You are a translator"}
      {:role "user" :content "Hello"}])

  (def body (vendor/build-request-body gemini-config "gemini-2.0-flash-exp" messages 0.3))

  (assert (get body :contents) "Should have contents")
  (assert (get body :systemInstruction) "Should have systemInstruction")
  (assert (get body :generationConfig) "Should have generationConfig")
  (assert (= (get-in body [:generationConfig :temperature]) 0.3) "Should have temperature in generationConfig")

  (print "build-request-body Gemini format test passed!"))

(defn test-parse-response-openai []
  (print "\nTesting parse-response for OpenAI format...")

  (def groq-config (vendor/get-vendor-config :groq))
  (def response
    {:choices @[{:message {:content "Translated text"}}]})

  (def result (vendor/parse-response groq-config response))
  (assert (= result "Translated text") "Should parse OpenAI response correctly")

  (print "parse-response OpenAI format test passed!"))

(defn test-parse-response-anthropic []
  (print "\nTesting parse-response for Anthropic format...")

  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (def response
    {:content @[{:text "Translated text"}]})

  (def result (vendor/parse-response anthropic-config response))
  (assert (= result "Translated text") "Should parse Anthropic response correctly")

  (print "parse-response Anthropic format test passed!"))

(defn test-parse-response-gemini []
  (print "\nTesting parse-response for Gemini format...")

  (def gemini-config (vendor/get-vendor-config :gemini))
  (def response
    {:candidates @[{:content {:parts @[{:text "Translated text"}]}}]})

  (def result (vendor/parse-response gemini-config response))
  (assert (= result "Translated text") "Should parse Gemini response correctly")

  (print "parse-response Gemini format test passed!"))

(defn test-auth-types []
  (print "\nTesting auth types for all vendors...")

  # Bearer auth vendors
  (def bearer-vendors [:groq :openai :deepseek :cerebras :openrouter :mistral])
  (each vendor bearer-vendors
    (def config (vendor/get-vendor-config vendor))
    (assert (= (get config :auth-type) :bearer)
            (string/format "%s should use Bearer auth" vendor)))

  # x-api-key auth (Anthropic)
  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (assert (= (get anthropic-config :auth-type) :x-api-key) "Anthropic should use x-api-key")

  # query-param auth (Gemini)
  (def gemini-config (vendor/get-vendor-config :gemini))
  (assert (= (get gemini-config :auth-type) :query-param) "Gemini should use query-param")

  (print "Auth types test passed!"))

(defn test-api-formats []
  (print "\nTesting API formats for all vendors...")

  # OpenAI format vendors
  (def openai-vendors [:groq :openai :deepseek :cerebras :openrouter :mistral])
  (each vendor openai-vendors
    (def config (vendor/get-vendor-config vendor))
    (assert (= (get config :api-format) :openai)
            (string/format "%s should use OpenAI format" vendor)))

  # Anthropic format
  (def anthropic-config (vendor/get-vendor-config :anthropic))
  (assert (= (get anthropic-config :api-format) :anthropic) "Anthropic should use Anthropic format")

  # Gemini format
  (def gemini-config (vendor/get-vendor-config :gemini))
  (assert (= (get gemini-config :api-format) :gemini) "Gemini should use Gemini format")

  (print "API formats test passed!"))

(defn main [&]
  (print "=== Running Vendor Module Tests ===\n")
  (test-vendor-configs-exist)
  (test-get-vendor-config)
  (test-build-url)
  (test-build-headers)
  (test-build-request-body-openai)
  (test-build-request-body-anthropic)
  (test-build-request-body-gemini)
  (test-parse-response-openai)
  (test-parse-response-anthropic)
  (test-parse-response-gemini)
  (test-auth-types)
  (test-api-formats)
  (print "\n=== All Vendor tests passed! ==="))
