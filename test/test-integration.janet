(import ../src/config)
(import ../src/cli)
(import ../src/init)
(import spork/json)
(import spork/sh)

# Test environment variables
(var original-xdg nil)
(var original-home nil)
(var original-api-keys @{})
(def test-dir "/tmp/tsl-integration-test")

# All API key environment variables to backup
(def api-key-vars
  ["GROQ_API_KEY" "OPENAI_API_KEY" "ANTHROPIC_API_KEY" "DEEPSEEK_API_KEY"
   "GEMINI_KEY" "MISTRAL_API_KEY" "OPENROUTER_API_KEY" "CEREBRAS_API_KEY"])

(defn setup-test-env []
  # Backup environment variables
  (set original-xdg (os/getenv "XDG_CONFIG_HOME"))
  (set original-home (os/getenv "HOME"))

  # Backup all API keys
  (set original-api-keys @{})
  (each key api-key-vars
    (put original-api-keys key (os/getenv key)))

  # Set test environment
  (os/setenv "XDG_CONFIG_HOME" test-dir)
  (os/setenv "HOME" test-dir)

  # Clear all API keys for clean test
  (each key api-key-vars
    (os/setenv key nil))

  # Clean up test directory
  (try
    (sh/exec "rm" "-rf" test-dir)
    ([err] nil)))

(defn cleanup-test-env []
  # Restore environment variables
  (if original-xdg
    (os/setenv "XDG_CONFIG_HOME" original-xdg)
    (os/setenv "XDG_CONFIG_HOME" nil))

  (if original-home
    (os/setenv "HOME" original-home)
    (os/setenv "HOME" nil))

  # Restore all API keys
  (each key api-key-vars
    (def original-val (get original-api-keys key))
    (if original-val
      (os/setenv key original-val)
      (os/setenv key nil)))

  # Clean up test directory
  (try
    (sh/exec "rm" "-rf" test-dir)
    ([err] nil)))

(defn test-full-workflow-save-load-parse []
  (print "Testing full workflow: save → load → parse...")
  (setup-test-env)

  # Step 1: Create and save a config
  (def test-config
    {:vendor "openai"
     :model "gpt-4o-mini"
     :source "Japanese"
     :target "Spanish"
     :temperature 0.5
     :copy false
     :api-key "test-api-key-123"})

  (def save-result (config/save-config test-config))
  (assert save-result "Config should be saved successfully")

  # Step 2: Load the config
  (def loaded-config (config/load-config))
  (assert (= (loaded-config :vendor) "openai") "Loaded vendor should match")
  (assert (= (loaded-config :model) "gpt-4o-mini") "Loaded model should match")
  (assert (= (loaded-config :source) "Japanese") "Loaded source should match")
  (assert (= (loaded-config :target) "Spanish") "Loaded target should match")
  (assert (= (loaded-config :temperature) 0.5) "Loaded temperature should match")
  (assert (= (loaded-config :copy) false) "Loaded copy should match")

  # Step 3: Parse CLI args with loaded config
  (def args @["hello" "-t" "French"])
  (def parsed (cli/parse-args args loaded-config))

  # Config values should be used except where overridden by CLI
  (assert (= (parsed :text) "hello") "Text should be parsed")
  (assert (= (parsed :source) "Japanese") "Source should come from config")
  (assert (= (parsed :target) "French") "Target should be overridden by CLI")
  (assert (= (parsed :temperature) 0.5) "Temperature should come from config")
  (assert (= (parsed :vendor) "openai") "Vendor should come from config")
  (assert (= (parsed :model) "gpt-4o-mini") "Model should come from config")

  (cleanup-test-env)
  (print "Full workflow test passed!"))

(defn test-api-key-priority-chain []
  (print "\nTesting API key priority chain...")
  (setup-test-env)

  # Step 1: No config, no env var → nil
  (os/setenv "GROQ_API_KEY" nil)
  (def conf1 (config/load-config))
  (def key1 (config/get-api-key conf1))
  (assert (nil? key1) "Should return nil when no API key available")

  # Step 2: No config, env var set → env var
  (os/setenv "GROQ_API_KEY" "env-key-value")
  (def conf2 (config/load-config))
  (def key2 (config/get-api-key conf2))
  (assert (= key2 "env-key-value") "Should use env var when no config")

  # Step 3: Config with api-key, env var set → env wins
  (def test-config {:vendor "groq" :api-key "config-key-value"})
  (config/save-config test-config)
  (os/setenv "GROQ_API_KEY" "env-key-value")

  (def conf3 (config/load-config))
  (def key3 (config/get-api-key conf3))
  (assert (= key3 "env-key-value") "Environment API key should take priority over config")

  (cleanup-test-env)
  (print "API key priority chain test passed!"))

(defn test-cli-config-default-priority []
  (print "\nTesting priority: CLI > Config > Default...")
  (setup-test-env)

  # Create custom config
  (def custom-config
    {:vendor "openai"
     :model "gpt-4o-mini"
     :source "Chinese"
     :target "Korean"
     :temperature 0.8
     :copy false})

  (config/save-config custom-config)

  # Load config (has custom values)
  (def loaded-config (config/load-config))

  # Test 1: No CLI flags → use config values
  (def args1 @["hello"])
  (def parsed1 (cli/parse-args args1 loaded-config))
  (assert (= (parsed1 :source) "Chinese") "Should use config source")
  (assert (= (parsed1 :target) "Korean") "Should use config target")
  (assert (= (parsed1 :temperature) 0.8) "Should use config temperature")
  (assert (= (parsed1 :copy) false) "Should use config copy")

  # Test 2: CLI flags override config
  (def args2 @["-s" "English" "-T" "0.3" "world"])
  (def parsed2 (cli/parse-args args2 loaded-config))
  (assert (= (parsed2 :source) "English") "CLI should override config source")
  (assert (= (parsed2 :target) "Korean") "Should keep config target")
  (assert (= (parsed2 :temperature) 0.3) "CLI should override config temperature")

  # Test 3: With default config (no file)
  (cleanup-test-env)
  (setup-test-env)

  (def default-config (config/load-config))
  (def args3 @["test"])
  (def parsed3 (cli/parse-args args3 default-config))
  (assert (= (parsed3 :source) "Korean") "Should use default source")
  (assert (= (parsed3 :target) "English") "Should use default target")
  (assert (= (parsed3 :temperature) 0.3) "Should use default temperature")

  (cleanup-test-env)
  (print "Priority chain test passed!"))

(defn test-init-scan-integration []
  (print "\nTesting init module API key scanning integration...")
  (setup-test-env)

  # setup-test-env already clears all API keys
  # Test 1: No API keys detected
  (def scan1 (init/scan-api-keys))
  (assert (= (length (scan1 :vendors)) 0) "Should find no vendors")

  # Test 2: Single API key
  (os/setenv "GROQ_API_KEY" "test-groq-key")
  (def scan2 (init/scan-api-keys))
  (assert (= (length (scan2 :vendors)) 1) "Should find one vendor")
  (assert (= (get (scan2 :vendors) 0) :groq) "Should detect Groq")

  # Test 3: Multiple API keys
  (os/setenv "OPENAI_API_KEY" "test-openai-key")
  (os/setenv "ANTHROPIC_API_KEY" "test-anthropic-key")
  (def scan3 (init/scan-api-keys))
  (assert (= (length (scan3 :vendors)) 3) "Should find three vendors")

  # Verify all three are detected
  (def vendors (scan3 :vendors))
  (assert (find |(= $ :groq) vendors) "Should include Groq")
  (assert (find |(= $ :openai) vendors) "Should include OpenAI")
  (assert (find |(= $ :anthropic) vendors) "Should include Anthropic")

  (cleanup-test-env)
  (print "Init scan integration test passed!"))

(defn test-scenario-new-user []
  (print "\nTesting scenario: New user (no config)...")
  (setup-test-env)

  # Simulate new user: no config file exists
  (assert (not (config/config-exists?)) "Config should not exist for new user")

  # Load config → should get defaults
  (def conf (config/load-config))
  (assert (= (conf :vendor) "groq") "New user should get default vendor")
  (assert (= (conf :source) "Korean") "New user should get default source")
  (assert (= (conf :target) "English") "New user should get default target")
  (assert (= (conf :temperature) 0.3) "New user should get default temperature")
  (assert (= (conf :copy) true) "New user should get default copy")

  # Parse args with defaults
  (def args @["안녕하세요"])
  (def parsed (cli/parse-args args conf))
  (assert (= (parsed :text) "안녕하세요") "Text should be parsed")
  (assert (= (parsed :source) "Korean") "Should use default source")
  (assert (= (parsed :target) "English") "Should use default target")

  (cleanup-test-env)
  (print "New user scenario test passed!"))

(defn test-scenario-existing-user []
  (print "\nTesting scenario: Existing user (with config)...")
  (setup-test-env)

  # Simulate existing user: create config file
  (def user-config
    {:vendor "anthropic"
     :model "claude-4-5-haiku-20241022"
     :source "English"
     :target "Japanese"
     :temperature 0.2
     :copy true})

  (config/save-config user-config)

  # User runs translation with config
  (assert (config/config-exists?) "Config should exist for existing user")

  (def conf (config/load-config))
  (assert (= (conf :vendor) "anthropic") "Should load user's vendor")
  (assert (= (conf :model) "claude-4-5-haiku-20241022") "Should load user's model")
  (assert (= (conf :source) "English") "Should load user's source")

  # Parse args with user's config
  (def args @["Hello world"])
  (def parsed (cli/parse-args args conf))
  (assert (= (parsed :source) "English") "Should use user's source")
  (assert (= (parsed :target) "Japanese") "Should use user's target")
  (assert (= (parsed :vendor) "anthropic") "Should use user's vendor")

  (cleanup-test-env)
  (print "Existing user scenario test passed!"))

(defn test-scenario-config-override []
  (print "\nTesting scenario: Config with CLI override...")
  (setup-test-env)

  # User has config but wants to override for this translation
  (def user-config
    {:vendor "groq"
     :model "groq/compound-mini"
     :source "Korean"
     :target "English"
     :temperature 0.3
     :copy true})

  (config/save-config user-config)

  # User runs with different target for this translation
  (def conf (config/load-config))
  (def args @["안녕하세요" "-t" "French" "-T" "0.7"])
  (def parsed (cli/parse-args args conf))

  (assert (= (parsed :source) "Korean") "Should keep config source")
  (assert (= (parsed :target) "French") "Should override target")
  (assert (= (parsed :temperature) 0.7) "Should override temperature")
  (assert (= (parsed :vendor) "groq") "Should keep config vendor")

  (cleanup-test-env)
  (print "Config override scenario test passed!"))

(defn test-cross-module-interaction []
  (print "\nTesting cross-module interaction...")
  (setup-test-env)

  # Test: init scan → config save → config load → cli parse
  (os/setenv "GROQ_API_KEY" "test-key-123")

  # Step 1: Scan API keys (init module)
  (def scan-result (init/scan-api-keys))
  (assert (> (length (scan-result :vendors)) 0) "Should detect API key")
  (def detected-vendor (get (scan-result :vendors) 0))

  # Step 2: Get models for detected vendor (init module)
  (def models (init/get-vendor-models detected-vendor))
  (assert (> (length models) 0) "Should have models for detected vendor")

  # Step 3: Create config with detected vendor and model (config module)
  (def new-config
    {:vendor (string detected-vendor)
     :model (get models 0)
     :source "Korean"
     :target "English"
     :temperature 0.3
     :copy true})

  (config/save-config new-config)

  # Step 4: Load config (config module)
  (def loaded (config/load-config))
  (assert (= (loaded :vendor) "groq") "Should match detected vendor")

  # Step 5: Parse CLI args with loaded config (cli module)
  (def args @["test"])
  (def parsed (cli/parse-args args loaded))
  (assert (= (parsed :vendor) "groq") "Should use vendor from config")
  (assert (= (parsed :model) (get models 0)) "Should use model from config")

  (cleanup-test-env)
  (print "Cross-module interaction test passed!"))

(defn test-config-file-merge []
  (print "\nTesting partial config file merging...")
  (setup-test-env)

  # Create partial config (only some fields)
  (def partial-config
    {:source "French"
     :target "German"})

  (config/save-config partial-config)

  # Load should merge with defaults
  (def conf (config/load-config))
  (assert (= (conf :source) "French") "Should use partial config value")
  (assert (= (conf :target) "German") "Should use partial config value")
  (assert (= (conf :vendor) "groq") "Should use default vendor")
  (assert (= (conf :model) "groq/compound-mini") "Should use default model")
  (assert (= (conf :temperature) 0.3) "Should use default temperature")
  (assert (= (conf :copy) true) "Should use default copy")

  (cleanup-test-env)
  (print "Config file merge test passed!"))

(defn main [&]
  (print "=== Running Integration Tests ===\n")
  (test-full-workflow-save-load-parse)
  (test-api-key-priority-chain)
  (test-cli-config-default-priority)
  (test-init-scan-integration)
  (test-scenario-new-user)
  (test-scenario-existing-user)
  (test-scenario-config-override)
  (test-cross-module-interaction)
  (test-config-file-merge)
  (print "\n=== All Integration tests passed! ==="))
