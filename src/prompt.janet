``Module for managing prompts and AI model parameters.

This module provides functions for:
- System prompts with detailed translation guidelines
- Temperature settings for translation accuracy
- Message construction for the Groq API
``

# Default temperature for translation (lower = more deterministic)
(def DEFAULT_TEMPERATURE 0.3)

(defn get-system-prompt
  ``Get the system prompt with detailed translation guidelines.

  Returns:
  A string containing comprehensive translation instructions.
  ``
  []

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
- For names and proper nouns, follow target language conventions``)

(defn build-messages
  ``Build the messages array for the API request.

  Arguments:
  - text: The text to translate
  - source-lang: Source language name
  - target-lang: Target language name

  Returns:
  An array of message structs with system and user roles.

  Example:
    (build-messages "Hello" "English" "Korean")
    # => @[{:role "system" :content "..."}
    #      {:role "user" :content "Translate from English to Korean: Hello"}]
  ``
  [text source-lang target-lang]

  (def system-message
    {:role "system"
     :content (get-system-prompt)})

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
