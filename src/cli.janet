(import ./config)

(defn print-usage
  ``Print usage information.``
  []
  (eprint "Usage: janet src/main.janet <text> [options]")
  (eprint "")
  (eprint "Options:")
  (eprint "  -s, --source <lang>      Source language (default: Korean)")
  (eprint "  -t, --target <lang>      Target language (default: English)")
  (eprint "  -T, --temperature <num>  Temperature 0.0-2.0 (default: 0.3)")
  (eprint "  --no-copy                Disable automatic clipboard copy")
  (eprint "  --init                   Run configuration wizard")
  (eprint "")
  (eprint "Examples:")
  (eprint "  janet src/main.janet \"안녕하세요\"")
  (eprint "  janet src/main.janet \"안녕하세요\" --target English")
  (eprint "  janet src/main.janet \"Hello\" -s English -t Korean")
  (eprint "  janet src/main.janet \"Bonjour\" -s French -t Korean -T 0.5")
  (eprint "  janet src/main.janet \"Hello\" --no-copy")
  (eprint "  janet src/main.janet --init"))

(defn print-init-suggestion
  ``Print suggestion to run --init if config doesn't exist.``
  []
  (eprint "")
  (eprint "Configuration file not found.")
  (eprint "Run with --init flag to set up your configuration:")
  (eprint "  janet src/main.janet --init")
  (eprint "")
  (eprint "Or continue with default settings (Groq, Korean->English)")
  (eprint ""))

(defn parse-args
  ``Parse command line arguments and merge with configuration.
  
  Priority: CLI Flags > Config File > Defaults
  ``
  [args config]
  
  # Start with values from config (which already contains defaults)
  (var text nil)
  (var source (get config :source))
  (var target (get config :target))
  (var temperature (get config :temperature))
  (var copy (get config :copy))
  (var init-mode false)
  (var i 0)

  (while (< i (length args))
    (def arg (get args i))
    (cond
      # Source language flags
      (or (= arg "--source") (= arg "-s"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set source (get args i))))

      # Target language flags
      (or (= arg "--target") (= arg "-t"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set target (get args i))))

      # Temperature flag
      (or (= arg "--temperature") (= arg "-T"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (def temp-str (get args i))
          (def parsed-temp (scan-number temp-str))
          (when parsed-temp
            (set temperature parsed-temp))))

      # No-copy flag
      (= arg "--no-copy")
      (set copy false)

      # Init flag
      (= arg "--init")
      (set init-mode true)

      # Positional argument (text)
      (nil? text)
      (set text arg)

      # Unknown flag
      (string/has-prefix? "--" arg)
      (do
        (eprintf "Unknown flag: %s" arg)
        (os/exit 1)))

    (set i (+ i 1)))

  {:text text
   :source source
   :target target
   :temperature temperature
   :copy copy
   :init init-mode
   :vendor (get config :vendor)
   :model (get config :model)
   :api-key (config/get-api-key config)})
