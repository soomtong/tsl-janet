(import ../src/config)
(import spork/json)
(import spork/sh)

# Test environment variables backup
(var original-xdg nil)
(var original-home nil)
(var original-groq-key nil)
(def test-config-dir "/tmp/tsl-test-config-janet")

(defn setup-test-env
  ``Set up test environment with temporary config directory.``
  []
  # Backup original environment variables
  (set original-xdg (os/getenv "XDG_CONFIG_HOME"))
  (set original-home (os/getenv "HOME"))
  (set original-groq-key (os/getenv "GROQ_API_KEY"))

  # Set test environment
  (os/setenv "XDG_CONFIG_HOME" test-config-dir)
  (os/setenv "HOME" test-config-dir)

  # Clean up any existing test directory
  (try
    (sh/exec "rm" "-rf" test-config-dir)
    ([err] nil)))

(defn cleanup-test-env
  ``Clean up test environment and restore original environment variables.``
  []
  # Restore original environment variables
  (if original-xdg
    (os/setenv "XDG_CONFIG_HOME" original-xdg)
    (os/setenv "XDG_CONFIG_HOME" nil))

  (if original-home
    (os/setenv "HOME" original-home)
    (os/setenv "HOME" nil))

  (if original-groq-key
    (os/setenv "GROQ_API_KEY" original-groq-key)
    (os/setenv "GROQ_API_KEY" nil))

  # Clean up test directory
  (try
    (sh/exec "rm" "-rf" test-config-dir)
    ([err] nil)))

(defn test-default-config []
  (print "Testing default-config structure...")

  # Check that default-config exists and has correct fields
  (assert (has-key? config/default-config :vendor) "default-config should have :vendor")
  (assert (has-key? config/default-config :model) "default-config should have :model")
  (assert (has-key? config/default-config :source) "default-config should have :source")
  (assert (has-key? config/default-config :target) "default-config should have :target")
  (assert (has-key? config/default-config :persona) "default-config should have :persona")
  (assert (has-key? config/default-config :temperature) "default-config should have :temperature")
  (assert (has-key? config/default-config :copy) "default-config should have :copy")

  # Check default values
  (assert (= (config/default-config :vendor) "groq") "Default vendor should be groq")
  (assert (= (config/default-config :model) "groq/compound-mini") "Default model should be groq/compound-mini")
  (assert (= (config/default-config :source) "Korean") "Default source should be Korean")
  (assert (= (config/default-config :target) "English") "Default target should be English")
  (assert (= (config/default-config :persona) "default") "Default persona should be default")
  (assert (= (config/default-config :temperature) 0.3) "Default temperature should be 0.3")
  (assert (= (config/default-config :copy) true) "Default copy should be true")

  # Check types
  (assert (string? (config/default-config :vendor)) "vendor should be string")
  (assert (string? (config/default-config :model)) "model should be string")
  (assert (string? (config/default-config :source)) "source should be string")
  (assert (string? (config/default-config :target)) "target should be string")
  (assert (string? (config/default-config :persona)) "persona should be string")
  (assert (number? (config/default-config :temperature)) "temperature should be number")
  (assert (= (type (config/default-config :copy)) :boolean) "copy should be boolean")

  (print "default-config structure test passed!"))

(defn test-load-config-no-file []
  (print "\nTesting load-config with no config file...")
  (setup-test-env)

  # Clear GROQ_API_KEY for clean test
  (os/setenv "GROQ_API_KEY" nil)

  # Load config when file doesn't exist
  (def conf (config/load-config))

  # Should return default config
  (assert (= (type conf) :struct) "Loaded config should be a struct")
  (assert (= (conf :vendor) "groq") "Should use default vendor")
  (assert (= (conf :source) "Korean") "Should use default source")
  (assert (= (conf :target) "English") "Should use default target")
  (assert (= (conf :temperature) 0.3) "Should use default temperature")
  (assert (= (conf :copy) true) "Should use default copy")

  (cleanup-test-env)
  (print "load-config no file test passed!"))

(defn test-load-config-with-file []
  (print "\nTesting load-config with valid config file...")
  (setup-test-env)

  # Create config directory
  (os/mkdir test-config-dir)
  (os/mkdir (string test-config-dir "/tsl"))

  # Create a custom config file
  (def custom-config
    {:vendor "openai"
     :model "gpt-4"
     :source "Japanese"
     :target "Spanish"
     :temperature 0.8
     :copy false})

  (def config-path (string test-config-dir "/tsl/config.json"))
  (spit config-path (json/encode custom-config))

  # Load config
  (def conf (config/load-config))

  # Should return custom config
  (assert (= (conf :vendor) "openai") "Should load custom vendor")
  (assert (= (conf :model) "gpt-4") "Should load custom model")
  (assert (= (conf :source) "Japanese") "Should load custom source")
  (assert (= (conf :target) "Spanish") "Should load custom target")
  (assert (= (conf :temperature) 0.8) "Should load custom temperature")
  (assert (= (conf :copy) false) "Should load custom copy")

  (cleanup-test-env)
  (print "load-config with file test passed!"))

(defn test-load-config-partial []
  (print "\nTesting load-config with partial config (merging)...")
  (setup-test-env)

  # Create config directory
  (os/mkdir test-config-dir)
  (os/mkdir (string test-config-dir "/tsl"))

  # Create a partial config (only override some fields)
  (def partial-config
    {:source "French"
     :target "German"})

  (def config-path (string test-config-dir "/tsl/config.json"))
  (spit config-path (json/encode partial-config))

  # Load config
  (def conf (config/load-config))

  # Should merge with defaults
  (assert (= (conf :source) "French") "Should use custom source")
  (assert (= (conf :target) "German") "Should use custom target")
  (assert (= (conf :vendor) "groq") "Should use default vendor")
  (assert (= (conf :model) "groq/compound-mini") "Should use default model")
  (assert (= (conf :temperature) 0.3) "Should use default temperature")
  (assert (= (conf :copy) true) "Should use default copy")

  (cleanup-test-env)
  (print "load-config partial config test passed!"))

(defn test-load-config-invalid-json []
  (print "\nTesting load-config with invalid JSON...")
  (setup-test-env)

  # Create config directory
  (os/mkdir test-config-dir)
  (os/mkdir (string test-config-dir "/tsl"))

  # Create an invalid JSON file
  (def config-path (string test-config-dir "/tsl/config.json"))
  (spit config-path "{invalid json content")

  # Load config (should print warning and return defaults)
  (def conf (config/load-config))

  # Should return default config on error
  (assert (= (conf :vendor) "groq") "Should fallback to default vendor on error")
  (assert (= (conf :source) "Korean") "Should fallback to default source on error")

  (cleanup-test-env)
  (print "load-config invalid JSON test passed!"))

(defn test-get-api-key-from-config []
  (print "\nTesting get-api-key from config...")
  (setup-test-env)

  # Clear environment variable
  (os/setenv "GROQ_API_KEY" nil)

  # Config with api-key
  (def conf {:vendor "groq" :api-key "config-key-123"})
  (def key (config/get-api-key conf))

  (assert (= key "config-key-123") "Should get API key from config")

  (cleanup-test-env)
  (print "get-api-key from config test passed!"))

(defn test-get-api-key-from-env []
  (print "\nTesting get-api-key from environment variable...")
  (setup-test-env)

  # Set environment variable
  (os/setenv "GROQ_API_KEY" "env-key-456")

  # Config without api-key
  (def conf {:vendor "groq"})
  (def key (config/get-api-key conf))

  (assert (= key "env-key-456") "Should get API key from environment")

  (cleanup-test-env)
  (print "get-api-key from env test passed!"))

(defn test-get-api-key-priority []
  (print "\nTesting get-api-key priority (env > config)...")
  (setup-test-env)

  # Set both config and environment
  (os/setenv "GROQ_API_KEY" "env-key-789")
  (def conf {:vendor "groq" :api-key "config-key-priority"})

  (def key (config/get-api-key conf))

  # Environment variable should take priority over config file
  (assert (= key "env-key-789") "Environment API key should take priority over config")

  (cleanup-test-env)
  (print "get-api-key priority test passed!"))

(defn test-get-api-key-none []
  (print "\nTesting get-api-key with no key available...")
  (setup-test-env)

  # Clear environment variable
  (os/setenv "GROQ_API_KEY" nil)

  # Config without api-key
  (def conf {:vendor "groq"})
  (def key (config/get-api-key conf))

  (assert (nil? key) "Should return nil when no API key available")

  (cleanup-test-env)
  (print "get-api-key none test passed!"))

(defn test-config-exists []
  (print "\nTesting config-exists?...")
  (setup-test-env)

  # Check when config doesn't exist
  (def exists1 (config/config-exists?))
  (assert (= exists1 false) "Should return false when config doesn't exist")

  # Create config directory and file
  (os/mkdir test-config-dir)
  (os/mkdir (string test-config-dir "/tsl"))
  (def config-path (string test-config-dir "/tsl/config.json"))
  (spit config-path "{}")

  # Check when config exists
  (def exists2 (config/config-exists?))
  (assert (= exists2 true) "Should return true when config exists")

  # Check return type
  (assert (= (type exists1) :boolean) "Should return boolean")
  (assert (= (type exists2) :boolean) "Should return boolean")

  (cleanup-test-env)
  (print "config-exists? test passed!"))

(defn test-save-config []
  (print "\nTesting save-config...")
  (setup-test-env)

  # Create a config to save
  (def test-config
    {:vendor "anthropic"
     :model "claude-3"
     :source "English"
     :target "French"
     :temperature 0.5
     :copy true
     :api-key "test-key-123"})

  # Save config
  (def result (config/save-config test-config))
  (assert (= result true) "save-config should return true on success")

  # Verify file was created
  (def config-path (string test-config-dir "/tsl/config.json"))
  (assert (os/stat config-path) "Config file should be created")

  # Verify file content
  (def content (slurp config-path))
  (def parsed (json/decode content true))

  (assert (= (parsed :vendor) "anthropic") "Saved vendor should match")
  (assert (= (parsed :model) "claude-3") "Saved model should match")
  (assert (= (parsed :source) "English") "Saved source should match")
  (assert (= (parsed :target) "French") "Saved target should match")
  (assert (= (parsed :temperature) 0.5) "Saved temperature should match")
  (assert (= (parsed :api-key) "test-key-123") "Saved api-key should match")

  (cleanup-test-env)
  (print "save-config test passed!"))

(defn test-save-and-load []
  (print "\nTesting save-config and load-config integration...")
  (setup-test-env)

  # Create and save a config
  (def original-config
    {:vendor "deepseek"
     :model "deepseek-chat"
     :source "Chinese"
     :target "Korean"
     :temperature 0.2
     :copy false})

  (config/save-config original-config)

  # Load it back
  (def loaded-config (config/load-config))

  # Verify all fields match
  (assert (= (loaded-config :vendor) "deepseek") "Loaded vendor should match")
  (assert (= (loaded-config :model) "deepseek-chat") "Loaded model should match")
  (assert (= (loaded-config :source) "Chinese") "Loaded source should match")
  (assert (= (loaded-config :target) "Korean") "Loaded target should match")
  (assert (= (loaded-config :temperature) 0.2) "Loaded temperature should match")
  (assert (= (loaded-config :copy) false) "Loaded copy should match")

  (cleanup-test-env)
  (print "save-config and load-config integration test passed!"))

(defn test-xdg-config-home []
  (print "\nTesting XDG_CONFIG_HOME handling...")
  (setup-test-env)

  # Test with XDG_CONFIG_HOME set
  (os/setenv "XDG_CONFIG_HOME" "/tmp/xdg-test")
  (os/mkdir "/tmp/xdg-test")
  (os/mkdir "/tmp/xdg-test/tsl")

  (def test-config {:vendor "test-vendor"})
  (config/save-config test-config)

  # Verify file is in XDG_CONFIG_HOME location
  (assert (os/stat "/tmp/xdg-test/tsl/config.json") "Config should be in XDG_CONFIG_HOME")

  # Clean up
  (sh/exec "rm" "-rf" "/tmp/xdg-test")

  # Test without XDG_CONFIG_HOME (should use HOME/.config)
  (os/setenv "XDG_CONFIG_HOME" nil)
  (os/setenv "HOME" "/tmp/home-test")
  (os/mkdir "/tmp/home-test")
  (os/mkdir "/tmp/home-test/.config")
  (os/mkdir "/tmp/home-test/.config/tsl")

  (config/save-config test-config)

  # Verify file is in HOME/.config location
  (assert (os/stat "/tmp/home-test/.config/tsl/config.json") "Config should be in HOME/.config")

  # Clean up
  (sh/exec "rm" "-rf" "/tmp/home-test")

  (cleanup-test-env)
  (print "XDG_CONFIG_HOME handling test passed!"))

(defn test-config-directory-creation []
  (print "\nTesting automatic directory creation...")
  (setup-test-env)

  # Ensure directory doesn't exist
  (assert (not (os/stat test-config-dir)) "Test directory should not exist initially")

  # Save config (should create directories)
  (def test-config {:vendor "test"})
  (def result (config/save-config test-config))

  (assert (= result true) "Should successfully create directories and save")
  (assert (os/stat test-config-dir) "Root directory should be created")
  (assert (os/stat (string test-config-dir "/tsl")) "tsl directory should be created")
  (assert (os/stat (string test-config-dir "/tsl/config.json")) "Config file should be created")

  (cleanup-test-env)
  (print "Automatic directory creation test passed!"))

(defn test-empty-config-file []
  (print "\nTesting load-config with empty config file...")
  (setup-test-env)

  # Create config directory
  (os/mkdir test-config-dir)
  (os/mkdir (string test-config-dir "/tsl"))

  # Create an empty JSON object
  (def config-path (string test-config-dir "/tsl/config.json"))
  (spit config-path "{}")

  # Load config
  (def conf (config/load-config))

  # Should merge with defaults (empty config means use all defaults)
  (assert (= (conf :vendor) "groq") "Should use default vendor with empty config")
  (assert (= (conf :source) "Korean") "Should use default source with empty config")
  (assert (= (conf :target) "English") "Should use default target with empty config")

  (cleanup-test-env)
  (print "Empty config file test passed!"))

(defn main [&]
  (print "=== Running Config Module Tests ===\n")
  (test-default-config)
  (test-load-config-no-file)
  (test-load-config-with-file)
  (test-load-config-partial)
  (test-load-config-invalid-json)
  (test-get-api-key-from-config)
  (test-get-api-key-from-env)
  (test-get-api-key-priority)
  (test-get-api-key-none)
  (test-config-exists)
  (test-save-config)
  (test-save-and-load)
  (test-xdg-config-home)
  (test-config-directory-creation)
  (test-empty-config-file)
  (print "\n=== All Config tests passed! ==="))
