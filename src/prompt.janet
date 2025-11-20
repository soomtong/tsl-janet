``Module for managing prompts and AI model parameters.

This module provides functions for:
- System prompts with detailed translation guidelines
- Persona-based prompt templates
- Temperature settings for translation accuracy
- Message construction for the Groq API
``

# Default temperature for translation (lower = more deterministic)
(def DEFAULT_TEMPERATURE 0.3)

# Persona-specific prompt additions
(def persona-prompts
  {:default "Provide balanced translations and rewrite Korean requirements into concise English instructions."
   :programming "Translate with focus on code generation clarity, highlight required tooling and versions, avoid fluff."
   :research "Translate and expand on intent to clarify research goals, cite assumptions, and keep tone formal."
   :review "Translate to English and point out potential gaps or validation steps, keeping feedback actionable."})

# Persona display names
(def persona-titles
  {:default "General bilingual assistant"
   :programming "Strict coding assistant"
   :research "Analytical researcher"
   :review "Peer reviewer"})

(defn validate-persona
  ``Validate that persona exists in persona-prompts.

  Arguments:
  - persona: Persona keyword or string to validate

  Returns:
  The validated persona keyword, or :default if invalid.
  ``
  [persona]

  (def persona-key
    (cond
      (nil? persona) :default
      (keyword? persona) persona
      (string? persona) (keyword persona)
      :default))

  (if (has-key? persona-prompts persona-key)
    persona-key
    :default))

(defn get-persona-list
  ``Get list of available persona keywords.

  Returns:
  Array of persona keywords.
  ``
  []
  (keys persona-prompts))

(defn get-system-prompt
  ``Get the system prompt with detailed translation guidelines.

  Arguments:
  - persona: Optional persona keyword (default: :default)

  Returns:
  A string containing comprehensive translation instructions with persona-specific additions.
  ``
  [&opt persona]

  (def validated-persona (validate-persona persona))
  (def persona-addition (get persona-prompts validated-persona))

  (string
    ``You are an expert translator with deep knowledge of multiple languages and cultural contexts.

Your task is to provide accurate, natural, and contextually appropriate translations.

Guidelines:
1. Accuracy: Translate the exact meaning without adding or omitting information
2. Naturalness: Use expressions that sound natural in the target language
3. Context preservation: Maintain the tone, formality, and style of the original
4. Cultural adaptation: Adjust idioms and cultural references when necessary
5. Grammar: Follow proper grammar rules of the target language
6. Consistency: Use consistent terminology throughout

When translating:
- For formal text, maintain formality
- For casual text, keep the casual tone
- For technical terms, use standard industry terminology
- For names and proper nouns, follow target language conventions

Persona-specific instruction: ``
    persona-addition))

(defn build-messages
  ``Build the messages array for the API request.

  Arguments:
  - text: The text to translate
  - source-lang: Source language name
  - target-lang: Target language name
  - persona: Optional persona keyword (default: :default)

  Returns:
  An array of message structs with system and user roles.

  Example:
    (build-messages "Hello" "English" "Korean")
    # => @[{:role "system" :content "..."}
    #      {:role "user" :content "Translate from English to Korean: Hello"}]
  ``
  [text source-lang target-lang &opt persona]

  (def system-message
    {:role "system"
     :content (get-system-prompt persona)})

  (def user-message
    {:role "user"
     :content (string "Translate from " source-lang " to " target-lang ": " text)})

  [system-message user-message])

(defn validate-temperature
  ``Validate that temperature is within acceptable range (0.0 to 2.0).

  Arguments:
  - temp: Temperature value to validate

  Returns:
  The validated temperature, or DEFAULT_TEMPERATURE if invalid.
  ``
  [temp]

  (cond
    (nil? temp) DEFAULT_TEMPERATURE
    (< temp 0) DEFAULT_TEMPERATURE
    (> temp 2) DEFAULT_TEMPERATURE
    temp))
