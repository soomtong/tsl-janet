# Vendor configuration and API format conversion module

# Vendor-specific configurations
(def vendor-configs
  ``Configuration for each LLM vendor.

  Structure:
  - :base-url - Base API URL
  - :endpoint - API endpoint path (or :endpoint-template for dynamic)
  - :auth-type - Authentication method (:bearer, :x-api-key, :query-param)
  - :api-format - API request/response format (:openai, :anthropic, :gemini)
  - :additional-headers - Optional extra headers (table)
  ``
  {:groq
   {:base-url "https://api.groq.com"
    :endpoint "/openai/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :openai
   {:base-url "https://api.openai.com"
    :endpoint "/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :deepseek
   {:base-url "https://api.deepseek.com"
    :endpoint "/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :cerebras
   {:base-url "https://api.cerebras.ai"
    :endpoint "/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :openrouter
   {:base-url "https://openrouter.ai"
    :endpoint "/api/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :mistral
   {:base-url "https://api.mistral.ai"
    :endpoint "/v1/chat/completions"
    :auth-type :bearer
    :api-format :openai}

   :anthropic
   {:base-url "https://api.anthropic.com"
    :endpoint "/v1/messages"
    :auth-type :x-api-key
    :api-format :anthropic
    :additional-headers {"anthropic-version" "2023-06-01"}}

   :gemini
   {:base-url "https://generativelanguage.googleapis.com"
    :endpoint-template "/v1/models/{model}:generateContent"
    :auth-type :query-param
    :api-format :gemini}})

(defn get-vendor-config
  ``Get configuration for a specific vendor.

  Arguments:
  - vendor: Vendor name (string or keyword)

  Returns:
  Vendor config struct, or default (groq) if vendor not found

  Example:
    (get-vendor-config "openai")
    (get-vendor-config :anthropic)
  ``
  [vendor]
  (def vendor-key
    (cond
      (keyword? vendor) vendor
      (string? vendor) (keyword vendor)
      :groq))  # fallback

  (get vendor-configs vendor-key (get vendor-configs :groq)))

(defn build-url
  ``Build full API URL for vendor.

  Arguments:
  - vendor-config: Vendor configuration struct
  - model: Model name (optional, needed for Gemini)
  - api-key: API key (optional, needed for Gemini query param auth)

  Returns:
  Full URL string

  Example:
    (build-url groq-config "groq/compound-mini")
    (build-url gemini-config "gemini-2.0-flash-exp" "api-key-here")
  ``
  [vendor-config &opt model api-key]

  (def base (get vendor-config :base-url))

  # Gemini uses model in URL path
  (def path
    (if-let [template (get vendor-config :endpoint-template)]
      (string/replace "{model}" (or model "model") template)
      (get vendor-config :endpoint)))

  # Gemini uses API key in query param
  (if (and (= (get vendor-config :auth-type) :query-param) api-key)
    (string base path "?key=" api-key)
    (string base path)))

(defn build-headers
  ``Build HTTP headers for vendor API.

  Arguments:
  - vendor-config: Vendor configuration struct
  - api-key: API key

  Returns:
  Struct with HTTP headers

  Example:
    (build-headers groq-config "api-key")
    # => @{"Content-Type" "application/json" "Authorization" "Bearer api-key"}
  ``
  [vendor-config api-key]

  (def headers @{"Content-Type" "application/json"})

  # Add authentication header based on vendor type
  (case (get vendor-config :auth-type)
    :bearer
    (put headers "Authorization" (string "Bearer " api-key))

    :x-api-key
    (put headers "x-api-key" api-key)

    # :query-param doesn't use auth header (goes in URL)
    nil)

  # Merge additional headers if present
  (when-let [additional (get vendor-config :additional-headers)]
    (merge-into headers additional))

  headers)

(defn build-request-body
  ``Build request body for vendor API.

  Converts from OpenAI format to vendor-specific format.

  Arguments:
  - vendor-config: Vendor configuration struct
  - model: Model name
  - messages: Messages array (OpenAI format with :role and :content)
  - temperature: Temperature value (0.0-2.0)

  Returns:
  Request body struct in vendor-specific format

  Example:
    (build-request-body groq-config "groq/compound-mini" messages 0.3)
  ``
  [vendor-config model messages temperature]

  (case (get vendor-config :api-format)
    # OpenAI-compatible format (Groq, OpenAI, DeepSeek, Cerebras, OpenRouter, Mistral)
    :openai
    {:model model
     :messages messages
     :temperature temperature}

    # Anthropic format (different structure)
    :anthropic
    (do
      # Separate system message from user messages
      (def system-msg (find |(= (get $ :role) "system") messages))
      (def user-msgs (filter |(not= (get $ :role) "system") messages))

      {:model model
       :max_tokens 4096  # Required by Anthropic
       :system (if system-msg (get system-msg :content) "")
       :messages user-msgs
       :temperature temperature})

    # Gemini format (different structure)
    :gemini
    (do
      # Separate system instruction
      (def system-msg (find |(= (get $ :role) "system") messages))
      (def user-msgs (filter |(not= (get $ :role) "system") messages))

      # Convert messages to Gemini format
      (def contents
        (map |(struct :role (get $ :role)
                      :parts @[{:text (get $ :content)}])
             user-msgs))

      (def body @{:contents contents
                  :generationConfig {:temperature temperature}})

      # Add system instruction if present
      (when system-msg
        (put body :systemInstruction {:parts @[{:text (get system-msg :content)}]}))

      body)

    # Default: OpenAI format
    {:model model
     :messages messages
     :temperature temperature}))

(defn parse-response
  ``Parse API response based on vendor format.

  Arguments:
  - vendor-config: Vendor configuration struct
  - response-body: Parsed JSON response (struct)

  Returns:
  Translated text string, or nil if parsing fails

  Example:
    (parse-response groq-config parsed-json)
  ``
  [vendor-config response-body]

  (case (get vendor-config :api-format)
    # OpenAI-compatible format
    :openai
    (get-in response-body [:choices 0 :message :content])

    # Anthropic format
    :anthropic
    (get-in response-body [:content 0 :text])

    # Gemini format
    :gemini
    (get-in response-body [:candidates 0 :content :parts 0 :text])

    # Default: OpenAI format
    (get-in response-body [:choices 0 :message :content])))
