(import ../src/config)
(import ../src/cli)

# Helper function to create test config
(defn make-test-config []
  {:vendor "groq"
   :model "groq/compound-mini"
   :source "Korean"
   :target "English"
   :persona "default"
   :temperature 0.3
   :copy true})

(defn test-short-flags []
  (print "Testing short form flags...")
  (def conf (make-test-config))

  # Test -s flag
  (def res1 (cli/parse-args @["-s" "Japanese" "hello"] conf))
  (assert (= (res1 :source) "Japanese") "-s flag should set source")
  (assert (= (res1 :text) "hello") "Text should be parsed")

  # Test -t flag
  (def res2 (cli/parse-args @["-t" "Spanish" "hello"] conf))
  (assert (= (res2 :target) "Spanish") "-t flag should set target")

  # Test -T flag
  (def res3 (cli/parse-args @["-T" "0.7" "hello"] conf))
  (assert (= (res3 :temperature) 0.7) "-T flag should set temperature")

  (print "Short flags test passed!"))

(defn test-long-flags []
  (print "\nTesting long form flags...")
  (def conf (make-test-config))

  # Test --source flag
  (def res1 (cli/parse-args @["--source" "Chinese" "hello"] conf))
  (assert (= (res1 :source) "Chinese") "--source flag should set source")

  # Test --target flag
  (def res2 (cli/parse-args @["--target" "German" "hello"] conf))
  (assert (= (res2 :target) "German") "--target flag should set target")

  # Test --temperature flag
  (def res3 (cli/parse-args @["--temperature" "1.5" "hello"] conf))
  (assert (= (res3 :temperature) 1.5) "--temperature flag should set temperature")

  # Test --no-copy flag
  (def res4 (cli/parse-args @["--no-copy" "hello"] conf))
  (assert (= (res4 :copy) false) "--no-copy flag should disable copy")

  # Test --init flag
  (def res5 (cli/parse-args @["--init"] conf))
  (assert (= (res5 :init) true) "--init flag should enable init mode")

  (print "Long flags test passed!"))

(defn test-flag-combinations []
  (print "\nTesting flag combinations...")
  (def conf (make-test-config))

  # Test multiple flags together
  (def res1 (cli/parse-args @["-s" "English" "-t" "Korean" "-T" "0.5" "test"] conf))
  (assert (= (res1 :source) "English") "Source should be English")
  (assert (= (res1 :target) "Korean") "Target should be Korean")
  (assert (= (res1 :temperature) 0.5) "Temperature should be 0.5")
  (assert (= (res1 :text) "test") "Text should be test")

  # Test mixed short and long flags
  (def res2 (cli/parse-args @["--source" "French" "-t" "Italian" "hello"] conf))
  (assert (= (res2 :source) "French") "Source should be French")
  (assert (= (res2 :target) "Italian") "Target should be Italian")

  # Test all flags together
  (def res3 (cli/parse-args @["-s" "Russian" "-t" "Portuguese" "-T" "0.1" "--no-copy" "world"] conf))
  (assert (= (res3 :source) "Russian") "Source should be Russian")
  (assert (= (res3 :target) "Portuguese") "Target should be Portuguese")
  (assert (= (res3 :temperature) 0.1) "Temperature should be 0.1")
  (assert (= (res3 :copy) false) "Copy should be false")
  (assert (= (res3 :text) "world") "Text should be world")

  # Test with persona flag included
  (def res4 (cli/parse-args @["-s" "Chinese" "-p" "programming" "-T" "0.5" "code"] conf))
  (assert (= (res4 :source) "Chinese") "Source should be Chinese")
  (assert (= (res4 :persona) "programming") "Persona should be programming")
  (assert (= (res4 :temperature) 0.5) "Temperature should be 0.5")
  (assert (= (res4 :text) "code") "Text should be code")

  (print "Flag combinations test passed!"))

(defn test-text-position []
  (print "\nTesting text position variations...")
  (def conf (make-test-config))

  # Text at the beginning
  (def res1 (cli/parse-args @["hello" "-s" "English" "-t" "Korean"] conf))
  (assert (= (res1 :text) "hello") "Text at beginning should be parsed")

  # Text at the end
  (def res2 (cli/parse-args @["-s" "English" "-t" "Korean" "world"] conf))
  (assert (= (res2 :text) "world") "Text at end should be parsed")

  # Text in the middle
  (def res3 (cli/parse-args @["-s" "English" "test" "-t" "Korean"] conf))
  (assert (= (res3 :text) "test") "Text in middle should be parsed")

  # Only text
  (def res4 (cli/parse-args @["just-text"] conf))
  (assert (= (res4 :text) "just-text") "Only text should be parsed")

  (print "Text position test passed!"))

(defn test-temperature-parsing []
  (print "\nTesting temperature parsing...")
  (def conf (make-test-config))

  # Integer temperature
  (def res1 (cli/parse-args @["-T" "1" "hello"] conf))
  (assert (= (res1 :temperature) 1) "Integer temperature should work")

  # Float temperature
  (def res2 (cli/parse-args @["-T" "0.5" "hello"] conf))
  (assert (= (res2 :temperature) 0.5) "Float temperature should work")

  # Zero temperature
  (def res3 (cli/parse-args @["--temperature" "0.0" "hello"] conf))
  (assert (= (res3 :temperature) 0.0) "Zero temperature should work")

  # High temperature
  (def res4 (cli/parse-args @["-T" "2.0" "hello"] conf))
  (assert (= (res4 :temperature) 2.0) "High temperature should work")

  # Invalid temperature (non-numeric) should keep default
  (def res5 (cli/parse-args @["-T" "invalid" "hello"] conf))
  (assert (= (res5 :temperature) 0.3) "Invalid temperature should keep default")

  (print "Temperature parsing test passed!"))

(defn test-priority []
  (print "\nTesting priority: CLI > Config > Defaults...")

  # Create custom config with different values
  (def custom-conf
    {:vendor "openai"
     :model "gpt-4"
     :source "Japanese"
     :target "Spanish"
     :persona "research"
     :temperature 0.8
     :copy false})

  # CLI flags should override config
  (def res1 (cli/parse-args @["-s" "English" "hello"] custom-conf))
  (assert (= (res1 :source) "English") "CLI source should override config")
  (assert (= (res1 :target) "Spanish") "Config target should be used when no CLI flag")

  # Config should override defaults (already tested in config loading)
  (def res2 (cli/parse-args @["hello"] custom-conf))
  (assert (= (res2 :source) "Japanese") "Config source should be used")
  (assert (= (res2 :target) "Spanish") "Config target should be used")
  (assert (= (res2 :persona) "research") "Config persona should be used")
  (assert (= (res2 :temperature) 0.8) "Config temperature should be used")
  (assert (= (res2 :copy) false) "Config copy should be used")

  # CLI --no-copy should override config copy=true
  (def default-conf (make-test-config))  # copy is true by default
  (def res3 (cli/parse-args @["--no-copy" "hello"] default-conf))
  (assert (= (res3 :copy) false) "CLI --no-copy should override config")

  (print "Priority test passed!"))

(defn test-return-structure []
  (print "\nTesting return value structure...")
  (def conf (make-test-config))

  # Parse with all defaults
  (def res (cli/parse-args @["hello"] conf))

  # Check all required fields exist
  (assert (has-key? res :text) "Result should have :text field")
  (assert (has-key? res :source) "Result should have :source field")
  (assert (has-key? res :target) "Result should have :target field")
  (assert (has-key? res :persona) "Result should have :persona field")
  (assert (has-key? res :temperature) "Result should have :temperature field")
  (assert (has-key? res :copy) "Result should have :copy field")
  (assert (has-key? res :init) "Result should have :init field")
  (assert (has-key? res :vendor) "Result should have :vendor field")
  (assert (has-key? res :model) "Result should have :model field")
  (assert (has-key? res :api-key) "Result should have :api-key field")

  # Check types
  (assert (or (string? (res :text)) (nil? (res :text))) "Text should be string or nil")
  (assert (string? (res :source)) "Source should be string")
  (assert (string? (res :target)) "Target should be string")
  (assert (string? (res :persona)) "Persona should be string")
  (assert (number? (res :temperature)) "Temperature should be number")
  (assert (= (type (res :copy)) :boolean) "Copy should be boolean")
  (assert (= (type (res :init)) :boolean) "Init should be boolean")
  (assert (string? (res :vendor)) "Vendor should be string")
  (assert (string? (res :model)) "Model should be string")

  (print "Return structure test passed!"))

(defn test-edge-cases []
  (print "\nTesting edge cases...")
  (def conf (make-test-config))

  # Empty args array
  (def res1 (cli/parse-args @[] conf))
  (assert (nil? (res1 :text)) "Empty args should have nil text")
  (assert (= (res1 :source) "Korean") "Empty args should use config defaults")

  # Only flags, no text
  (def res2 (cli/parse-args @["-s" "English" "-t" "French"] conf))
  (assert (nil? (res2 :text)) "No text should result in nil")
  (assert (= (res2 :source) "English") "Flags should still be parsed")

  # Flag without value at end (should be ignored/keep default)
  (def res3 (cli/parse-args @["hello" "-s"] conf))
  (assert (= (res3 :text) "hello") "Text should be parsed")
  # -s without value should keep the default since there's no next arg
  (assert (= (res3 :source) "Korean") "Missing flag value should keep default")

  # Init flag with text (text should be ignored for init)
  (def res4 (cli/parse-args @["--init" "hello"] conf))
  (assert (= (res4 :init) true) "Init flag should be set")
  (assert (= (res4 :text) "hello") "Text after init should still be parsed")

  (print "Edge cases test passed!"))

(defn test-print-functions []
  (print "\nTesting print functions...")

  # These functions just print to stderr, so we just verify they're callable
  (assert (function? cli/print-usage) "print-usage should be a function")
  (assert (function? cli/print-init-suggestion) "print-init-suggestion should be a function")

  # Call them to ensure they don't crash (output will go to stderr)
  (try
    (cli/print-usage)
    ([err]
      (error "print-usage should not throw error")))

  (try
    (cli/print-init-suggestion)
    ([err]
      (error "print-init-suggestion should not throw error")))

  (print "Print functions test passed!"))

(defn test-no-copy-flag []
  (print "\nTesting --no-copy flag behavior...")
  (def conf (make-test-config))

  # Default should have copy=true
  (def res1 (cli/parse-args @["hello"] conf))
  (assert (= (res1 :copy) true) "Default copy should be true")

  # With --no-copy
  (def res2 (cli/parse-args @["--no-copy" "hello"] conf))
  (assert (= (res2 :copy) false) "--no-copy should set copy to false")

  # Config with copy=false, no flag
  (def conf-no-copy
    {:vendor "groq"
     :model "groq/compound-mini"
     :source "Korean"
     :target "English"
     :persona "default"
     :temperature 0.3
     :copy false})

  (def res3 (cli/parse-args @["hello"] conf-no-copy))
  (assert (= (res3 :copy) false) "Config copy=false should be respected")

  (print "--no-copy flag test passed!"))

(defn test-init-flag-variations []
  (print "\nTesting --init flag variations...")
  (def conf (make-test-config))

  # Only --init
  (def res1 (cli/parse-args @["--init"] conf))
  (assert (= (res1 :init) true) "--init alone should work")
  (assert (nil? (res1 :text)) "--init alone should have no text")

  # --init with other flags
  (def res2 (cli/parse-args @["--init" "-s" "English"] conf))
  (assert (= (res2 :init) true) "--init with flags should work")
  (assert (= (res2 :source) "English") "Other flags should be parsed with --init")

  # Default (no --init)
  (def res3 (cli/parse-args @["hello"] conf))
  (assert (= (res3 :init) false) "Default init should be false")

  (print "--init flag variations test passed!"))

(defn test-persona-flag []
  (print "\nTesting --persona flag behavior...")
  (def conf (make-test-config))

  # Test 1: Default should have persona="default"
  (def res1 (cli/parse-args @["hello"] conf))
  (assert (= (res1 :persona) "default") "Default persona should be 'default'")

  # Test 2: --persona programming
  (def res2 (cli/parse-args @["--persona" "programming" "hello"] conf))
  (assert (= (res2 :persona) "programming") "--persona should set persona")

  # Test 3: -p short form
  (def res3 (cli/parse-args @["-p" "research" "hello"] conf))
  (assert (= (res3 :persona) "research") "-p flag should set persona")

  # Test 4: Persona with other flags
  (def res4 (cli/parse-args @["-s" "English" "--persona" "review" "test"] conf))
  (assert (= (res4 :persona) "review") "Persona should work with other flags")
  (assert (= (res4 :source) "English") "Other flags should still work")

  # Test 5: Config with different persona
  (def conf-prog
    {:vendor "groq"
     :model "groq/compound-mini"
     :source "Korean"
     :target "English"
     :persona "programming"
     :temperature 0.3
     :copy true})

  (def res5 (cli/parse-args @["hello"] conf-prog))
  (assert (= (res5 :persona) "programming") "Config persona should be used")

  # Test 6: CLI overrides config persona
  (def res6 (cli/parse-args @["--persona" "research" "hello"] conf-prog))
  (assert (= (res6 :persona) "research") "CLI persona should override config")

  (print "Persona flag test passed!"))

(defn main [&]
  (print "=== Running CLI Module Tests ===\n")
  (test-short-flags)
  (test-long-flags)
  (test-flag-combinations)
  (test-text-position)
  (test-temperature-parsing)
  (test-priority)
  (test-return-structure)
  (test-edge-cases)
  (test-print-functions)
  (test-no-copy-flag)
  (test-init-flag-variations)
  (test-persona-flag)
  (print "\n=== All CLI tests passed! ==="))
