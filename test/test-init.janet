(import ../src/init)
(import ../src/config)

# Backup environment variables
(var original-env @{})

(defn backup-env
  ``Backup API key environment variables.``
  []
  (each key (keys init/api-key-mapping)
    (put original-env key (os/getenv key))))

(defn restore-env
  ``Restore original environment variables.``
  []
  (each [key val] (pairs original-env)
    (if val
      (os/setenv key val)
      (os/setenv key nil))))

(defn clear-api-keys
  ``Clear all API key environment variables.``
  []
  (each key (keys init/api-key-mapping)
    (os/setenv key nil)))

(defn test-api-key-mapping []
  (print "Testing api-key-mapping structure...")

  # Check that all expected keys exist
  (def expected-keys
    ["GEMINI_KEY" "OPENAI_API_KEY" "ANTHROPIC_API_KEY" "MISTRAL_API_KEY"
     "DEEPSEEK_API_KEY" "OPENROUTER_API_KEY" "CEREBRAS_API_KEY" "GROQ_API_KEY"])

  (each key expected-keys
    (assert (has-key? init/api-key-mapping key)
            (string/format "%s should be in api-key-mapping" key)))

  # Check that values are keywords
  (each [key val] (pairs init/api-key-mapping)
    (assert (= (type val) :keyword)
            (string/format "Mapping for %s should be a keyword" key)))

  (print "api-key-mapping structure test passed!"))

(defn test-vendor-names []
  (print "\nTesting vendor-names structure...")

  # Check that all vendors have display names
  (def expected-vendors
    [:groq :openai :anthropic :deepseek :gemini :mistral :openrouter :cerebras])

  (each vendor expected-vendors
    (assert (has-key? init/vendor-names vendor)
            (string/format "%s should have a display name" vendor))
    (assert (string? (get init/vendor-names vendor))
            (string/format "Display name for %s should be a string" vendor)))

  (print "vendor-names structure test passed!"))

(defn test-vendor-models []
  (print "\nTesting vendor-models structure...")

  # Check that all vendors have model lists
  (def expected-vendors
    [:groq :openai :anthropic :deepseek :gemini :mistral :openrouter :cerebras])

  (each vendor expected-vendors
    (assert (has-key? init/vendor-models vendor)
            (string/format "%s should have models defined" vendor))
    (def models (get init/vendor-models vendor))
    (assert (array? models)
            (string/format "Models for %s should be an array" vendor))
    (assert (> (length models) 0)
            (string/format "%s should have at least one model" vendor)))

  (print "vendor-models structure test passed!"))

(defn test-scan-api-keys-none []
  (print "\nTesting scan-api-keys with no keys...")
  (backup-env)
  (clear-api-keys)

  (def result (init/scan-api-keys))

  (assert (has-key? result :vendors) "Result should have :vendors")
  (assert (has-key? result :keys) "Result should have :keys")
  (assert (array? (result :vendors)) ":vendors should be an array")
  (assert (= (length (result :vendors)) 0) "Should find no vendors")

  (restore-env)
  (print "scan-api-keys with no keys test passed!"))

(defn test-scan-api-keys-single []
  (print "\nTesting scan-api-keys with single key...")
  (backup-env)
  (clear-api-keys)

  # Set only GROQ_API_KEY
  (os/setenv "GROQ_API_KEY" "test-key-123")

  (def result (init/scan-api-keys))

  (assert (= (length (result :vendors)) 1) "Should find one vendor")
  (assert (= (get (result :vendors) 0) :groq) "Should detect Groq")
  (assert (= (get (result :keys) :groq) "GROQ_API_KEY") "Should map to GROQ_API_KEY")

  (restore-env)
  (print "scan-api-keys with single key test passed!"))

(defn test-scan-api-keys-multiple []
  (print "\nTesting scan-api-keys with multiple keys...")
  (backup-env)
  (clear-api-keys)

  # Set multiple API keys
  (os/setenv "GROQ_API_KEY" "groq-key")
  (os/setenv "OPENAI_API_KEY" "openai-key")
  (os/setenv "ANTHROPIC_API_KEY" "anthropic-key")

  (def result (init/scan-api-keys))

  (assert (= (length (result :vendors)) 3) "Should find three vendors")

  # Check that all three vendors are detected (order doesn't matter)
  (def vendors (result :vendors))
  (assert (find |(= $ :groq) vendors) "Should detect Groq")
  (assert (find |(= $ :openai) vendors) "Should detect OpenAI")
  (assert (find |(= $ :anthropic) vendors) "Should detect Anthropic")

  # Check key mappings
  (assert (= (get (result :keys) :groq) "GROQ_API_KEY"))
  (assert (= (get (result :keys) :openai) "OPENAI_API_KEY"))
  (assert (= (get (result :keys) :anthropic) "ANTHROPIC_API_KEY"))

  (restore-env)
  (print "scan-api-keys with multiple keys test passed!"))

(defn test-get-vendor-models []
  (print "\nTesting get-vendor-models function...")

  # Test valid vendors
  (def groq-models (init/get-vendor-models :groq))
  (assert (array? groq-models) "Should return array for valid vendor")
  (assert (> (length groq-models) 0) "Groq should have models")
  (assert (find |(= $ "groq/compound-mini") groq-models) "Groq should have compound-mini")

  (def openai-models (init/get-vendor-models :openai))
  (assert (> (length openai-models) 0) "OpenAI should have models")

  # Test invalid vendor
  (def invalid-models (init/get-vendor-models :invalid-vendor))
  (assert (array? invalid-models) "Should return array for invalid vendor")
  (assert (= (length invalid-models) 0) "Invalid vendor should return empty array")

  (print "get-vendor-models test passed!"))

(defn test-all-vendors-have-models []
  (print "\nTesting all vendors have valid model lists...")

  (each [vendor models] (pairs init/vendor-models)
    # Check each model is a string
    (each model models
      (assert (string? model)
              (string/format "Model '%s' for vendor %s should be a string" model vendor))))

  (print "All vendors have valid model lists test passed!"))

(defn test-vendor-consistency []
  (print "\nTesting consistency between data structures...")

  # All vendors in api-key-mapping should have display names
  (each [env-var vendor] (pairs init/api-key-mapping)
    (assert (has-key? init/vendor-names vendor)
            (string/format "Vendor %s should have a display name" vendor)))

  # All vendors in vendor-names should have models
  (each [vendor name] (pairs init/vendor-names)
    (assert (has-key? init/vendor-models vendor)
            (string/format "Vendor %s should have models defined" vendor)))

  (print "Vendor consistency test passed!"))

(defn test-common-languages []
  (print "\nTesting common-languages structure...")

  (assert (array? init/common-languages) "common-languages should be an array")
  (assert (> (length init/common-languages) 0) "Should have at least one language")

  # Check that all are strings
  (each lang init/common-languages
    (assert (string? lang)
            (string/format "Language '%s' should be a string" lang)))

  # Check for expected languages
  (assert (find |(= $ "Korean") init/common-languages) "Should include Korean")
  (assert (find |(= $ "English") init/common-languages) "Should include English")
  (assert (find |(= $ "Japanese") init/common-languages) "Should include Japanese")

  (print "common-languages structure test passed!"))

(defn test-specific-api-key-detection []
  (print "\nTesting specific API key detection...")
  (backup-env)
  (clear-api-keys)

  # Test each API key individually
  (def test-cases
    [["GEMINI_KEY" :gemini "Gemini"]
     ["OPENAI_API_KEY" :openai "OpenAI"]
     ["ANTHROPIC_API_KEY" :anthropic "Anthropic"]
     ["MISTRAL_API_KEY" :mistral "Mistral"]
     ["DEEPSEEK_API_KEY" :deepseek "DeepSeek"]
     ["OPENROUTER_API_KEY" :openrouter "OpenRouter"]
     ["CEREBRAS_API_KEY" :cerebras "Cerebras"]
     ["GROQ_API_KEY" :groq "Groq"]])

  (each [env-var expected-vendor expected-name] test-cases
    (clear-api-keys)
    (os/setenv env-var "test-value")

    (def result (init/scan-api-keys))
    (assert (= (length (result :vendors)) 1)
            (string/format "Should find exactly one vendor for %s" env-var))
    (assert (= (get (result :vendors) 0) expected-vendor)
            (string/format "%s should map to %s" env-var expected-vendor)))

  (restore-env)
  (print "Specific API key detection test passed!"))

(defn test-prompt-api-key-exists []
  (print "\nTesting prompt-api-key function exists...")

  # Check that prompt-api-key function exists
  (assert (function? init/prompt-api-key) "prompt-api-key should be a function")

  # Note: Cannot easily test interactive input, but we verify:
  # - Function exists and is callable
  # - Has proper docstring
  (def docstring (get (dyn 'init/prompt-api-key) :doc))
  (assert docstring "prompt-api-key should have documentation")
  (assert (string/find "validation" docstring) "Documentation should mention validation")
  (assert (string/find "retry" docstring) "Documentation should mention retry")

  (print "prompt-api-key function exists test passed!"))

(defn test-config-building-with-table []
  (print "\nTesting config building with table (mutable)...")

  # Simulate init wizard config creation
  # This tests the fix for struct -> table change

  # Create config as table (mutable)
  (var test-config
    @{:vendor "groq"
      :model "groq/compound-mini"
      :source "Korean"
      :target "English"
      :persona "default"
      :temperature 0.3
      :copy true})

  # Verify it's a table (not struct)
  (assert (table? test-config) "Config should be a table")
  (assert (not (struct? test-config)) "Config should not be a struct")

  # Test that we can add api-key using put (this would fail with struct)
  (def api-key-value "test-api-key-12345678901234567890")
  (put test-config :api-key api-key-value)

  # Verify api-key was added
  (assert (= (get test-config :api-key) api-key-value) "API key should be added to config")

  # Verify all original keys are still present
  (assert (= (get test-config :vendor) "groq") "Vendor should be preserved")
  (assert (= (get test-config :model) "groq/compound-mini") "Model should be preserved")
  (assert (= (get test-config :source) "Korean") "Source should be preserved")
  (assert (= (get test-config :target) "English") "Target should be preserved")
  (assert (= (get test-config :persona) "default") "Persona should be preserved")
  (assert (= (get test-config :temperature) 0.3) "Temperature should be preserved")
  (assert (= (get test-config :copy) true) "Copy should be preserved")

  (print "Config building with table test passed!"))

(defn test-config-save-with-api-key []
  (print "\nTesting config save with API key...")
  (backup-env)
  (clear-api-keys)

  # Set XDG_CONFIG_HOME to temp directory
  (def test-dir "/tmp/tsl-test-init-save")
  (os/setenv "XDG_CONFIG_HOME" test-dir)

  # Clean up any existing test directory
  (try
    (os/execute ["rm" "-rf" test-dir] :p)
    ([err] nil))

  # Create config with API key using table
  (var new-config
    @{:vendor "groq"
      :model "groq/compound-mini"
      :source "Korean"
      :target "English"
      :persona "default"
      :temperature 0.3
      :copy true})

  # Add API key (simulating init wizard behavior)
  (def api-key "test-key-1234567890abcdefghij")
  (put new-config :api-key api-key)

  # Save config using config module
  (def save-result (config/save-config new-config))

  # Verify save was successful
  (assert save-result "Config save should succeed")

  # Verify file was created
  (def config-path (string test-dir "/tsl/config.json"))
  (assert (os/stat config-path) "Config file should exist")

  # Load and verify saved config
  (def loaded-config (config/load-config))
  (assert (= (get loaded-config :vendor) "groq") "Loaded vendor should match")
  (assert (= (get loaded-config :model) "groq/compound-mini") "Loaded model should match")
  (assert (= (get loaded-config :api-key) api-key) "Loaded API key should match")
  (assert (= (get loaded-config :temperature) 0.3) "Loaded temperature should match")

  # Clean up
  (try
    (os/execute ["rm" "-rf" test-dir] :p)
    ([err] nil))

  (restore-env)
  (print "Config save with API key test passed!"))

(defn main [&]
  (print "=== Running Init Module Tests ===\n")
  (test-api-key-mapping)
  (test-vendor-names)
  (test-vendor-models)
  (test-scan-api-keys-none)
  (test-scan-api-keys-single)
  (test-scan-api-keys-multiple)
  (test-get-vendor-models)
  (test-all-vendors-have-models)
  (test-vendor-consistency)
  (test-common-languages)
  (test-specific-api-key-detection)
  (test-prompt-api-key-exists)
  (test-config-building-with-table)
  (test-config-save-with-api-key)
  (print "\n=== All Init tests passed! ==="))
