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
  (def config-path (get-config-path))
  (if (os/stat config-path)
    (try
      (let [content (slurp config-path)
            json-config (json/decode content true)]
        (merge default-config json-config))
      ([err]
        (eprint "Warning: Failed to parse config file: " err)
        default-config))
    default-config))

(defn get-api-key [config]
  # Priority: 1. Config file 2. Environment variables
  (or (get config :api-key)
      (os/getenv "GROQ_API_KEY")))

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
  ``
  [config]

  (def config-dir (get-config-dir))
  (def config-path (get-config-path))

  # Create parent directory first (.config)
  (def parent-dir (path/dirname config-dir))
  (try
    (os/mkdir parent-dir)
    ([err] nil))  # Ignore error if directory already exists

  # Create config directory (tsl)
  (try
    (os/mkdir config-dir)
    ([err] nil))  # Ignore error if directory already exists

  # Write config to file
  (try
    (do
      (spit config-path (json/encode config))
      (print "Configuration saved to: " config-path)
      true)
    ([err]
      (eprint "Failed to save config: " err)
      false)))
