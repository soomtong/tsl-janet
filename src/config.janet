(import spork/json)
(import spork/path)
(import ./prompt)

(def default-config
  {:vendor "groq"
   :model "groq/compound-mini"
   :source "Korean"
   :target "English"
   :persona "default"
   :temperature prompt/DEFAULT_TEMPERATURE
   :copy true})

(defn- get-config-dir []
  (if-let [xdg-config (os/getenv "XDG_CONFIG_HOME")]
    (path/join xdg-config "tsl")
    (path/join (os/getenv "HOME") ".config" "tsl")))

(defn- get-config-path []
  (path/join (get-config-dir) "config.json"))

(defn load-config []
  ``Load configuration from config.json file.

  Returns:
  Configuration struct merged with defaults. If config file doesn't exist or
  fails to load, returns default configuration.

  Errors:
  - File read errors: Returns default config with warning
  - JSON parse errors: Returns default config with warning
  - Permission errors: Returns default config with warning
  ``
  (def config-path (get-config-path))
  (if (os/stat config-path)
    (try
      (let [content (slurp config-path)
            json-config (json/decode content true)]
        (merge default-config json-config))
      ([err]
        (eprint "")
        (eprint "Warning: Failed to load config file: " config-path)
        (eprint "Reason: " err)
        (eprint "")
        (eprint "Using default configuration. Run --init to reconfigure.")
        (eprint "")
        default-config))
    default-config))

(defn get-api-key [config]
  ``Get API key from environment or config file.

  Priority order:
  1. Environment variable (GROQ_API_KEY, OPENAI_API_KEY, etc.)
  2. Config file stored key

  Arguments:
  - config: Configuration struct

  Returns:
  API key string, or nil if not found
  ``
  # Priority: 1. Environment variables 2. Config file
  (def vendor (get config :vendor "groq"))

  # Map vendor to environment variable
  (def env-var-map
    {"groq" "GROQ_API_KEY"
     "openai" "OPENAI_API_KEY"
     "anthropic" "ANTHROPIC_API_KEY"
     "deepseek" "DEEPSEEK_API_KEY"
     "gemini" "GEMINI_KEY"
     "mistral" "MISTRAL_API_KEY"
     "openrouter" "OPENROUTER_API_KEY"
     "cerebras" "CEREBRAS_API_KEY"})

  (def env-var (get env-var-map vendor))

  # Try environment variable first, then config file
  (or (when env-var (os/getenv env-var))
      (get config :api-key)))

(defn config-exists?
  ``Check if config file exists.

  Returns:
  true if config file exists, false otherwise
  ``
  []
  (not (nil? (os/stat (get-config-path)))))

(defn save-config
  ``Save configuration to config.json file.

  Creates config directory if it doesn't exist.
  Writes config to XDG_CONFIG_HOME/tsl/config.json.

  Arguments:
  - config: Configuration struct to save

  Returns:
  true on success, false on failure

  Errors:
  - Directory creation failure (permissions)
  - File write failure (permissions, disk space)
  - JSON encoding failure
  ``
  [config]

  (def config-dir (get-config-dir))
  (def config-path (get-config-path))

  # Create parent directory first (.config)
  (def parent-dir (path/dirname config-dir))
  (try
    (os/mkdir parent-dir)
    ([err]
      # Check if it's not just "already exists" error
      (unless (os/stat parent-dir)
        (eprint "")
        (eprint "Error: Failed to create parent directory: " parent-dir)
        (eprint "Reason: " err)
        (eprint "Please check directory permissions.")
        (eprint "")
        (error "Directory creation failed"))))

  # Create config directory (tsl)
  (try
    (os/mkdir config-dir)
    ([err]
      # Check if it's not just "already exists" error
      (unless (os/stat config-dir)
        (eprint "")
        (eprint "Error: Failed to create config directory: " config-dir)
        (eprint "Reason: " err)
        (eprint "Please check directory permissions.")
        (eprint "")
        (error "Directory creation failed"))))

  # Write config to file
  (try
    (do
      (def json-str (json/encode config))
      (spit config-path json-str)
      (print "Configuration saved to: " config-path)
      true)
    ([err]
      (eprint "")
      (eprint "Error: Failed to save config file: " config-path)
      (eprint "Reason: " err)
      (eprint "")
      (eprint "Possible causes:")
      (eprint "  - Insufficient disk space")
      (eprint "  - File permission denied")
      (eprint "  - Directory is read-only")
      (eprint "")
      (eprint "Please check file permissions and available disk space.")
      (eprint "")
      false)))
