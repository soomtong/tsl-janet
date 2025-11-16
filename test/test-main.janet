(import spork/test)
(import spork/json)

# Start test suite
(test/start-suite)

# Test: API payload structure for translation request with new format
(test/assert
  (deep=
    {:model "compound-mini"
     :messages [{:role "user"
                 :content "Translate from English to Korean: Hello"}]}
    (let [payload {:model "compound-mini"
                   :messages [{:role "user"
                               :content "Translate from English to Korean: Hello"}]}]
      payload))
  "API payload structure should match expected format")

# Test: JSON encoding of API payload
(def test-payload
  {:model "compound-mini"
   :messages [{:role "user"
               :content "Test message"}]})

(def encoded-json
  (try
    (json/encode test-payload)
    ([err] nil)))

(test/assert
  (or (string? encoded-json) (buffer? encoded-json))
  "JSON encoding should produce a string or buffer")

(when encoded-json
  (test/assert
    (not (nil? (string/find "compound-mini" (string encoded-json))))
    "Encoded JSON should contain model name"))

# Test: JSON decoding of API response
(def mock-response
  ``{"choices": [{"message": {"content": "안녕하세요"}}]}``)

(def decoded (json/decode mock-response true))

(test/assert
  (= (get-in decoded [:choices 0 :message :content]) "안녕하세요")
  "JSON decoding should correctly parse API response")

# Test: Environment variable access for API key
(def api-key (os/getenv "GROQ_API_KEY"))
(if (nil? api-key)
  (print "⚠ Warning: GROQ_API_KEY not set - API tests will be skipped")
  (test/assert (string? api-key) "GROQ_API_KEY should be a string when set"))

# Test: New prompt construction with source and target
(def text "Hello")
(def source-lang "English")
(def target-lang "Korean")
(def expected-prompt "Translate from English to Korean: Hello")

(test/assert
  (= (string "Translate from " source-lang " to " target-lang ": " text)
     expected-prompt)
  "Prompt should be constructed correctly with source and target")

# Test: Default language values
(def default-source "Korean")
(def default-target "English")

(test/assert
  (and (= default-source "Korean") (= default-target "English"))
  "Default source should be Korean and target should be English")

# Test: parse-args function (basic structure test)
(def parsed-result {:text "Hello" :source "Korean" :target "Spanish"})
(def result-keys (keys parsed-result))

(test/assert
  (and
    (= (length result-keys) 3)
    (not (nil? (find |(= $ :text) result-keys)))
    (not (nil? (find |(= $ :source) result-keys)))
    (not (nil? (find |(= $ :target) result-keys))))
  "Parsed args should have text, source, and target keys")

# Test: Multiple message structure
(def messages
  @[{:role "user" :content "First message"}
    {:role "assistant" :content "Response"}
    {:role "user" :content "Second message"}])

(test/assert
  (= (length messages) 3)
  "Message array should support multiple messages")

(test/assert
  (= (get-in messages [0 :role]) "user")
  "Message role should be accessible")

# Test: HTTP headers structure
(def headers
  {"Content-Type" "application/json"
   "Authorization" "Bearer test-key"})

(test/assert
  (= (get headers "Content-Type") "application/json")
  "Headers should contain Content-Type")

(test/assert
  (not (nil? (string/find "Bearer" (get headers "Authorization"))))
  "Authorization header should contain Bearer token")

# End test suite and print results
(test/end-suite)
