(import ../src/prompt)

(defn test-persona-prompts-structure []
  (print "Testing persona-prompts structure...")

  # Check that all expected personas exist
  (def expected-personas [:default :programming :research :review])

  (each persona expected-personas
    (assert (has-key? prompt/persona-prompts persona)
            (string/format "%s should exist in persona-prompts" persona))
    (assert (string? (get prompt/persona-prompts persona))
            (string/format "Prompt for %s should be a string" persona)))

  (print "persona-prompts structure test passed!"))

(defn test-persona-titles-structure []
  (print "\nTesting persona-titles structure...")

  # Check that all expected personas have titles
  (def expected-personas [:default :programming :research :review])

  (each persona expected-personas
    (assert (has-key? prompt/persona-titles persona)
            (string/format "%s should have a title" persona))
    (assert (string? (get prompt/persona-titles persona))
            (string/format "Title for %s should be a string" persona)))

  (print "persona-titles structure test passed!"))

(defn test-validate-persona []
  (print "\nTesting validate-persona function...")

  # Test valid personas
  (assert (= (prompt/validate-persona :default) :default) "Should validate :default")
  (assert (= (prompt/validate-persona :programming) :programming) "Should validate :programming")
  (assert (= (prompt/validate-persona "research") :research) "Should convert string to keyword")

  # Test invalid personas
  (assert (= (prompt/validate-persona :invalid) :default) "Invalid persona should return :default")
  (assert (= (prompt/validate-persona nil) :default) "nil should return :default")
  (assert (= (prompt/validate-persona "unknown") :default) "Unknown string should return :default")

  (print "validate-persona test passed!"))

(defn test-get-persona-list []
  (print "\nTesting get-persona-list function...")

  (def personas (prompt/get-persona-list))

  (assert (or (array? personas) (tuple? personas)) "Should return array or tuple")
  (assert (>= (length personas) 4) "Should have at least 4 personas")

  # Check that all expected personas are in the list
  (assert (find |(= $ :default) personas) "Should include :default")
  (assert (find |(= $ :programming) personas) "Should include :programming")
  (assert (find |(= $ :research) personas) "Should include :research")
  (assert (find |(= $ :review) personas) "Should include :review")

  (print "get-persona-list test passed!"))

(defn test-get-system-prompt-default []
  (print "\nTesting get-system-prompt with default persona...")

  (def prompt1 (prompt/get-system-prompt))
  (def prompt2 (prompt/get-system-prompt :default))

  (assert (string? prompt1) "Should return string")
  (assert (string? prompt2) "Should return string with explicit :default")
  (assert (> (length prompt1) 100) "Prompt should be substantial")

  # Check that prompt contains base translation guidelines
  (assert (string/find "translator" prompt1) "Should mention translator")
  (assert (string/find "Guidelines:" prompt1) "Should contain guidelines")

  # Check that it contains the default persona instruction
  (def default-instruction (get prompt/persona-prompts :default))
  (assert (string/find default-instruction prompt1) "Should contain default persona instruction")

  (print "get-system-prompt default test passed!"))

(defn test-get-system-prompt-personas []
  (print "\nTesting get-system-prompt with different personas...")

  (def default-prompt (prompt/get-system-prompt :default))
  (def programming-prompt (prompt/get-system-prompt :programming))
  (def research-prompt (prompt/get-system-prompt :research))
  (def review-prompt (prompt/get-system-prompt :review))

  # All should be strings
  (assert (string? default-prompt) "default should be string")
  (assert (string? programming-prompt) "programming should be string")
  (assert (string? research-prompt) "research should be string")
  (assert (string? review-prompt) "review should be string")

  # Each should contain their specific persona instruction
  (assert (string/find (get prompt/persona-prompts :default) default-prompt)
          "default prompt should contain default instruction")
  (assert (string/find (get prompt/persona-prompts :programming) programming-prompt)
          "programming prompt should contain programming instruction")
  (assert (string/find (get prompt/persona-prompts :research) research-prompt)
          "research prompt should contain research instruction")
  (assert (string/find (get prompt/persona-prompts :review) review-prompt)
          "review prompt should contain review instruction")

  # Different personas should produce different prompts
  (assert (not= default-prompt programming-prompt) "default and programming should differ")
  (assert (not= default-prompt research-prompt) "default and research should differ")
  (assert (not= programming-prompt review-prompt) "programming and review should differ")

  (print "get-system-prompt personas test passed!"))

(defn test-build-messages-default []
  (print "\nTesting build-messages with default persona...")

  (def messages (prompt/build-messages "Hello" "English" "Korean"))

  (assert (indexed? messages) "Should return indexed collection")
  (assert (= (length messages) 2) "Should have 2 messages")

  # Check system message
  (def system-msg (get messages 0))
  (assert (= (system-msg :role) "system") "First message should be system")
  (assert (string? (system-msg :content)) "System content should be string")
  (assert (> (length (system-msg :content)) 100) "System content should be substantial")

  # Check user message
  (def user-msg (get messages 1))
  (assert (= (user-msg :role) "user") "Second message should be user")
  (assert (string/find "English" (user-msg :content)) "User message should mention source language")
  (assert (string/find "Korean" (user-msg :content)) "User message should mention target language")
  (assert (string/find "Hello" (user-msg :content)) "User message should contain text")

  (print "build-messages default test passed!"))

(defn test-build-messages-with-persona []
  (print "\nTesting build-messages with specific persona...")

  (def messages-default (prompt/build-messages "test" "English" "Korean" :default))
  (def messages-prog (prompt/build-messages "test" "English" "Korean" :programming))

  (assert (= (length messages-default) 2) "default should have 2 messages")
  (assert (= (length messages-prog) 2) "programming should have 2 messages")

  # System messages should differ based on persona
  (def system-default (get (get messages-default 0) :content))
  (def system-prog (get (get messages-prog 0) :content))

  (assert (not= system-default system-prog) "System messages should differ by persona")
  (assert (string/find (get prompt/persona-prompts :default) system-default)
          "Should contain default persona instruction")
  (assert (string/find (get prompt/persona-prompts :programming) system-prog)
          "Should contain programming persona instruction")

  # User messages should be identical
  (def user-default (get (get messages-default 1) :content))
  (def user-prog (get (get messages-prog 1) :content))
  (assert (= user-default user-prog) "User messages should be identical")

  (print "build-messages with persona test passed!"))

(defn test-validate-temperature []
  (print "\nTesting validate-temperature function...")

  # Valid temperatures
  (assert (= (prompt/validate-temperature 0.0) 0.0) "Should accept 0.0")
  (assert (= (prompt/validate-temperature 0.5) 0.5) "Should accept 0.5")
  (assert (= (prompt/validate-temperature 1.0) 1.0) "Should accept 1.0")
  (assert (= (prompt/validate-temperature 2.0) 2.0) "Should accept 2.0")

  # Invalid temperatures should return default
  (assert (= (prompt/validate-temperature nil) prompt/DEFAULT_TEMPERATURE) "nil should return default")
  (assert (= (prompt/validate-temperature -1) prompt/DEFAULT_TEMPERATURE) "Negative should return default")
  (assert (= (prompt/validate-temperature 3) prompt/DEFAULT_TEMPERATURE) "Too high should return default")

  (print "validate-temperature test passed!"))

(defn test-default-temperature []
  (print "\nTesting DEFAULT_TEMPERATURE constant...")

  (assert (number? prompt/DEFAULT_TEMPERATURE) "DEFAULT_TEMPERATURE should be a number")
  (assert (= prompt/DEFAULT_TEMPERATURE 0.3) "DEFAULT_TEMPERATURE should be 0.3")
  (assert (>= prompt/DEFAULT_TEMPERATURE 0.0) "DEFAULT_TEMPERATURE should be >= 0.0")
  (assert (<= prompt/DEFAULT_TEMPERATURE 2.0) "DEFAULT_TEMPERATURE should be <= 2.0")

  (print "DEFAULT_TEMPERATURE test passed!"))

(defn main [&]
  (print "=== Running Prompt Module Tests ===\n")
  (test-persona-prompts-structure)
  (test-persona-titles-structure)
  (test-validate-persona)
  (test-get-persona-list)
  (test-get-system-prompt-default)
  (test-get-system-prompt-personas)
  (test-build-messages-default)
  (test-build-messages-with-persona)
  (test-validate-temperature)
  (test-default-temperature)
  (print "\n=== All Prompt tests passed! ==="))
