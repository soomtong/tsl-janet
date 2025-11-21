(import ./config)

(defn print-init-suggestion
  ``Print suggestion to run --init if config doesn't exist.``
  []
  (eprint "")
  (eprint "Configuration file not found.")
  (eprint "Run with --init flag to set up your configuration:")
  (eprint "  tsl --init")
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
  (var persona (get config :persona))
  (var temperature (get config :temperature))
  (var vendor (get config :vendor))
  (var model (get config :model))
  (var copy (get config :copy))
  (var init-mode false)
  (var show-config false)
  (var show-prompt false)
  (var show-persona false)
  (var show-help false)
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

      # Persona flag
      (or (= arg "--persona") (= arg "-p"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set persona (get args i))))

      # Temperature flag
      (or (= arg "--temperature") (= arg "-T"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (def temp-str (get args i))
          (def parsed-temp (scan-number temp-str))
          (when parsed-temp
            (set temperature parsed-temp))))

      # Vendor flag
      (or (= arg "--vendor") (= arg "-V"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set vendor (get args i))))

      # Model flag
      (or (= arg "--model") (= arg "-m"))
      (do
        (set i (+ i 1))
        (when (< i (length args))
          (set model (get args i))))

      # No-copy flag
      (= arg "--no-copy")
      (set copy false)

      # Init flag
      (= arg "--init")
      (set init-mode true)

      # Show-config flag
      (= arg "--show-config")
      (set show-config true)

      # Show-prompt flag
      (= arg "--show-prompt")
      (set show-prompt true)

      # Show-persona flag
      (= arg "--show-persona")
      (set show-persona true)

      # Help flag
      (or (= arg "--help") (= arg "-h"))
      (set show-help true)

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
   :persona persona
   :temperature temperature
   :vendor vendor
   :model model
   :copy copy
   :init init-mode
   :show-config show-config
   :show-prompt show-prompt
   :show-persona show-persona
   :help show-help
   :api-key (config/get-api-key config)})
