(import ./config)
(import ./prompt)

# API Key environment variable to vendor mapping
(def api-key-mapping
  {"GEMINI_KEY" :gemini
   "OPENAI_API_KEY" :openai
   "ANTHROPIC_API_KEY" :anthropic
   "MISTRAL_API_KEY" :mistral
   "DEEPSEEK_API_KEY" :deepseek
   "OPENROUTER_API_KEY" :openrouter
   "CEREBRAS_API_KEY" :cerebras
   "GROQ_API_KEY" :groq})

# Vendor display names
(def vendor-names
  {:groq "Groq"
   :openai "OpenAI"
   :anthropic "Anthropic"
   :deepseek "DeepSeek"
   :gemini "Gemini"
   :mistral "Mistral"
   :openrouter "OpenRouter"
   :cerebras "Cerebras"})

# Models available for each vendor
(def vendor-models
  {:groq @["groq/compound-mini" "groq/compound"]
   :openai @["gpt-4o-mini" "gpt-3.5-turbo"]
   :anthropic @["claude-4-5-haiku-20241022"]
   :deepseek @["deepseek-chat" "deepseek-reasoner"]
   :gemini @["gemini-2.0-flash-exp" "gemini-1.5-pro" "gemini-1.5-flash"]
   :mistral @["mistral-large-latest" "mistral-small-latest"]
   :openrouter @["openrouter/auto"]
   :cerebras @["cerebras/llama3.1-8b"]})

# Common languages
(def common-languages
  @["Korean" "English" "Japanese" "Chinese" "Spanish"
    "French" "German" "Russian" "Portuguese" "Italian"])

(defn scan-api-keys
  ``Scan environment variables for API keys.

  Returns:
  A struct with :vendors (array of available vendor keywords) and
  :keys (struct mapping vendor to env var name)
  ``
  []
  (var available-vendors @[])
  (var key-map @{})

  (each [env-var vendor] (pairs api-key-mapping)
    (when (os/getenv env-var)
      (array/push available-vendors vendor)
      (put key-map vendor env-var)))

  {:vendors available-vendors
   :keys key-map})

(defn get-vendor-models
  ``Get model list for a specific vendor.

  Arguments:
  - vendor: Vendor keyword (e.g., :groq, :openai)

  Returns:
  Array of model names, or empty array if vendor not found
  ``
  [vendor]
  (or (get vendor-models vendor) @[]))

(defn prompt-input
  ``Display a prompt and get user input.

  Arguments:
  - prompt-text: Text to display before input
  - default-value: Optional default value (shown in prompt)

  Returns:
  User input string, or default value if input is empty
  ``
  [prompt-text &opt default-value]

  (if default-value
    (eprintf "%s (default: %s): " prompt-text default-value)
    (eprintf "%s: " prompt-text))

  (flush)
  (def input (string/trim (getline)))

  (if (and default-value (= (length input) 0))
    default-value
    input))

(defn prompt-choice
  ``Display a numbered list and get user choice.

  Arguments:
  - prompt-text: Text to display above choices
  - choices: Array of choice strings
  - default-index: Optional default choice (0-indexed)

  Returns:
  Selected index (0-indexed), or nil on invalid input
  ``
  [prompt-text choices &opt default-index]

  (eprint "")
  (eprint prompt-text)
  (each i (range (length choices))
    (def choice (get choices i))
    (eprintf "  %d. %s%s"
             (+ i 1)
             choice
             (if (and default-index (= i default-index)) " (recommended)" "")))

  (eprint "")
  (def prompt-suffix
    (if default-index
      (string/format " (default: %d): " (+ default-index 1))
      ": "))

  (eprintf "Select option (1-%d)%s" (length choices) prompt-suffix)
  (flush)

  (def input (string/trim (getline)))

  # If empty and default exists, use default
  (if (and default-index (= (length input) 0))
    default-index
    # Otherwise try to parse number
    (let [num (scan-number input)]
      (if (and num (>= num 1) (<= num (length choices)))
        (- num 1)  # Convert to 0-indexed
        nil))))

(defn prompt-yes-no
  ``Display a yes/no prompt.

  Arguments:
  - prompt-text: Text to display
  - default-yes: If true, default is yes; if false, default is no

  Returns:
  true for yes, false for no
  ``
  [prompt-text &opt default-yes]

  (def suffix (if default-yes " (Y/n): " " (y/N): "))
  (eprintf "%s%s" prompt-text suffix)
  (flush)

  (def input (string/trim (string/ascii-lower (getline))))

  (cond
    (= (length input) 0) default-yes
    (or (= input "y") (= input "yes")) true
    (or (= input "n") (= input "no")) false
    default-yes))  # Invalid input uses default

(defn run-init-wizard
  ``Run the interactive initialization wizard.

  Scans for API keys, prompts user for configuration choices,
  and saves the configuration to file.
  ``
  []

  (print "")
  (print "=== TSL Configuration Wizard ===")
  (print "")

  # Step 1: Scan for API keys
  (print "Scanning for API keys...")
  (def scan-result (scan-api-keys))
  (def available-vendors (scan-result :vendors))
  (def key-map (scan-result :keys))

  (if (> (length available-vendors) 0)
    (do
      (each vendor available-vendors
        (def env-var (get key-map vendor))
        (printf "✓ Found %s (%s)" env-var (get vendor-names vendor))))
    (print "⚠ No API keys found in environment variables"))

  (print "")

  # Step 2: Select vendor
  (var selected-vendor nil)
  (var vendor-name nil)

  (if (> (length available-vendors) 0)
    (do
      # Build choice list
      (def vendor-choices
        (map |(get vendor-names $) available-vendors))

      # Find groq in available vendors, default to it if found
      (def default-idx
        (or (find-index |(= $ :groq) available-vendors) 0))

      (def vendor-idx
        (prompt-choice
          "Available vendors:"
          vendor-choices
          default-idx))  # Default to groq if available, otherwise first vendor

      (if vendor-idx
        (do
          (set selected-vendor (get available-vendors vendor-idx))
          (set vendor-name (get vendor-names selected-vendor)))
        (do
          (eprint "Invalid selection. Using default (Groq).")
          (set selected-vendor :groq)
          (set vendor-name "Groq"))))
    (do
      # No API keys found, ask user to choose or use default
      (eprint "No API keys detected. Using default vendor (Groq).")
      (eprint "You can set GROQ_API_KEY environment variable later.")
      (set selected-vendor :groq)
      (set vendor-name "Groq")))

  (print "")
  (printf "Selected vendor: %s" vendor-name)

  # Step 3: Select model
  (def models (get-vendor-models selected-vendor))
  (var selected-model nil)

  (if (> (length models) 0)
    (do
      (def model-idx
        (prompt-choice
          (string "Available models for " vendor-name ":")
          models
          0))  # Default to first model

      (if model-idx
        (set selected-model (get models model-idx))
        (set selected-model (get models 0))))  # Fallback to first
    (do
      # No models defined, use generic
      (set selected-model "default")))

  (print "")
  (printf "Selected model: %s" selected-model)

  # Step 4: Source language
  (print "")
  (def source-lang (prompt-input "Source language" "Korean"))

  # Step 5: Target language
  (def target-lang (prompt-input "Target language" "English"))

  # Step 6: Temperature
  (print "")
  (def temp-input (prompt-input "Temperature (0.0-2.0)" "0.3"))
  (def temperature
    (let [parsed (scan-number temp-input)]
      (if (and parsed (>= parsed 0.0) (<= parsed 2.0))
        parsed
        0.3)))

  # Step 7: Clipboard copy
  (print "")
  (def copy-enabled (prompt-yes-no "Enable clipboard copy by default?" true))

  # Step 8: Save API key (optional)
  (print "")
  (def save-api-key (prompt-yes-no "Save API key to config file?" false))

  (var api-key-value nil)
  (when save-api-key
    (def env-var (get key-map selected-vendor))
    (if env-var
      (set api-key-value (os/getenv env-var))
      (do
        (print "")
        (set api-key-value (prompt-input (string "Enter " vendor-name " API key"))))))

  # Build configuration
  (var new-config
    {:vendor (string selected-vendor)
     :model selected-model
     :source source-lang
     :target target-lang
     :temperature temperature
     :copy copy-enabled})

  (when api-key-value
    (put new-config :api-key api-key-value))

  # Save configuration
  (print "")
  (print "Saving configuration...")
  (def save-result (config/save-config new-config))

  (if save-result
    (do
      (print "")
      (print "✓ Configuration saved successfully!")
      (print "")
      (print "=== Configuration Summary ===")
      (printf "Vendor:       %s" vendor-name)
      (printf "Model:        %s" selected-model)
      (printf "Source:       %s" source-lang)
      (printf "Target:       %s" target-lang)
      (printf "Temperature:  %.1f" temperature)
      (printf "Clipboard:    %s" (if copy-enabled "enabled" "disabled"))
      (when api-key-value
        (printf "API Key:      saved"))
      (print "")
      (print "You can now use: janet src/main.janet \"your text\""))
    (do
      (eprint "")
      (eprint "✗ Failed to save configuration.")
      (eprint "Please check file permissions and try again."))))
