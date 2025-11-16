(import spork/test)

# Start test suite
(test/start-suite)

# Test: Environment variable handling
(test/assert
  (= (type (os/getenv "PATH")) :string)
  "Environment variables should be accessible")

# Test: GROQ_API_KEY presence (warning only, not failure)
(def groq-key (os/getenv "GROQ_API_KEY"))
(if (nil? groq-key)
  (print "⚠ Warning: GROQ_API_KEY not set in environment")
  (test/assert (string? groq-key) "GROQ_API_KEY should be a string"))

# Test: Basic string operations
(test/assert
  (= (string/trim " hello ") "hello")
  "String trimming should work")

(test/assert
  (not (nil? (string/find "https" "https://api.groq.com")))
  "URL should contain https")

# Test: JSON-like structure (for API payload)
(test/assert
  (= (type {:model "compound-mini"
            :messages []})
     :struct)
  "API payload structure should be a struct")

# Test: Array operations (for messages)
(def test-messages @[])
(array/push test-messages {:role "user" :content "test"})
(test/assert
  (= (length test-messages) 1)
  "Message array operations should work")

# Test: Basic arithmetic
(test/assert
  (= (+ 1 2 3) 6)
  "Basic arithmetic should work")

# End test suite and print results
(test/end-suite)
