# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

tsl-janet is a production-ready translation CLI tool built with Janet language supporting 8 LLM vendors (Groq, OpenAI, Anthropic, DeepSeek, Gemini, Mistral, OpenRouter, Cerebras). The tool provides a unified interface to multiple LLM providers with vendor-specific API format conversion, automatic authentication handling, and intelligent retry logic. It features a modular architecture with configuration management, persona-based translation, and comprehensive error handling.

## Development Commands

### Testing
```bash
# Recommended: Run all tests with jpm
jpm test

# This will automatically run all test files:
# - test/test-basics.janet
# - test/test-main.janet
# - test/test-cli.janet
# - test/test-config.janet
# - test/test-init.janet
# - test/test-prompt.janet
# - test/test-vendor.janet
# - test/test-integration.janet (full workflow tests)

# Or run individual test files
janet test/test-basics.janet
janet test/test-integration.janet

# Install test dependency (spork) if needed
jpm deps
```

### Running the CLI
```bash
# First-time setup (interactive configuration wizard)
janet src/main.janet --init

# Basic usage with defaults (Korean → English)
janet src/main.janet "안녕하세요"

# Specify target language only
janet src/main.janet "안녕하세요" --target Spanish
janet src/main.janet "안녕하세요" -t French

# Specify both source and target languages
janet src/main.janet "Hello world" --source English --target Korean
janet src/main.janet "Bonjour" -s French -t Korean

# With temperature control
janet src/main.janet "안녕하세요" -T 0.1  # More accurate
janet src/main.janet "Hello" -s English -t Korean --temperature 0.7  # More creative

# With persona selection
janet src/main.janet "코드 작성" --persona programming
janet src/main.janet "연구 논문" -p research

# With clipboard control
janet src/main.janet "안녕하세요" --no-copy  # Disable automatic clipboard copy

# With vendor and model selection
janet src/main.janet "Hello" --vendor openai --model gpt-4o-mini
janet src/main.janet "Hello" -V anthropic -m claude-4-5-haiku-20241022
janet src/main.janet "Hello" --vendor gemini --model gemini-2.0-flash-exp

# Show configuration
janet src/main.janet --show-config   # Display current settings
janet src/main.janet --show-prompt   # Display system prompt
janet src/main.janet --show-persona  # Display persona info
```

## Configuration System

### Configuration Priority
The tool follows this priority order (highest to lowest):
1. **CLI flags** - Command line arguments override everything
2. **Config file** - `~/.config/tsl/config.json` (or `$XDG_CONFIG_HOME/tsl/config.json`)
3. **Environment variables** - `GROQ_API_KEY` and other vendor API keys
4. **Defaults** - Built-in defaults (Korean → English, temperature 0.3)

### Configuration File Location
- Uses XDG Base Directory specification
- Path: `$XDG_CONFIG_HOME/tsl/config.json` or `~/.config/tsl/config.json`
- Created automatically by `--init` wizard
- File format: JSON with keys: `vendor`, `model`, `source`, `target`, `persona`, `temperature`, `copy`, `api-key` (optional)

### API Key Management
Supported vendors and their environment variables:
- Groq: `GROQ_API_KEY`
- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`
- DeepSeek: `DEEPSEEK_API_KEY`
- Gemini: `GEMINI_KEY`
- Mistral: `MISTRAL_API_KEY`
- OpenRouter: `OPENROUTER_API_KEY`
- Cerebras: `CEREBRAS_API_KEY`

API keys can be stored in config file (optional) or environment variables. The `--init` wizard scans for available keys and offers to save them to config.

## Code Architecture

The project is organized into modular components with clear separation of concerns:

### Module Structure

**Core Modules:**
- `src/main.janet` - CLI entry point and translation execution
  - `make-llm-request` - Multi-vendor API communication with retry logic and error handling
  - `parse-http-response` - Parses HTTP response with status code extraction
  - `handle-http-error` - Error handling for various HTTP status codes (401/403/429/5xx)
  - `show-config` / `show-prompt` / `show-persona` - Configuration display utilities
  - `main` - Entry point with argument parsing and workflow orchestration

- `src/cli.janet` - Command-line argument parsing
  - `parse-args` - Parses CLI flags and merges with config (priority: CLI > Config > Defaults)
  - `print-usage` - Usage information display
  - `print-init-suggestion` - Suggests running `--init` for new users

- `src/config.janet` - Configuration file management
  - `load-config` - Loads config from XDG path, merges with defaults
  - `save-config` - Saves config to JSON file
  - `get-api-key` - API key resolution (config file > environment variable)
  - `config-exists?` - Checks if config file exists

- `src/init.janet` - Interactive initialization wizard
  - `run-init-wizard` - Guides user through configuration setup
  - `scan-api-keys` - Scans environment for available API keys
  - `get-vendor-models` - Returns available models for each vendor
  - `prompt-input` / `prompt-choice` / `prompt-yes-no` - Interactive input utilities

- `src/prompt.janet` - Prompt templates and persona management
  - `DEFAULT_TEMPERATURE` - Constant (0.3)
  - `persona-prompts` - Map of persona-specific instructions
  - `persona-titles` - Display names for personas
  - `get-system-prompt` - Returns translation guidelines with persona customization
  - `build-messages` - Constructs API message array
  - `validate-temperature` / `validate-persona` - Input validation

- `src/vendor.janet` - Multi-vendor API abstraction layer
  - `vendor-configs` - Configuration map for 8 LLM vendors (base URLs, endpoints, auth types, API formats)
  - `get-vendor-config` - Retrieves vendor-specific configuration
  - `build-url` - Constructs vendor-specific API URLs (handles Gemini's model-in-path pattern)
  - `build-headers` - Builds authentication headers (Bearer, x-api-key, or query-param)
  - `build-request-body` - Converts messages to vendor-specific format (OpenAI/Anthropic/Gemini)
  - `parse-response` - Extracts translated text from vendor-specific response formats

### Persona System

Four specialized translation personas available:
- `:default` - Balanced translations with concise English output
- `:programming` - Code-focused clarity, highlights tooling/versions
- `:research` - Formal tone, clarifies research goals, cites assumptions
- `:review` - Translation with gap analysis and actionable feedback

Each persona modifies the system prompt to produce contextually appropriate translations.

### Test Organization

- `test/test-*.janet` - Unit tests for individual modules
- `test/test-integration.janet` - Full workflow tests including:
  - Save → Load → Parse workflow
  - API key priority chain validation
  - CLI/Config/Default priority verification
  - Cross-module interaction scenarios
  - New user vs. existing user scenarios

Integration tests use temporary directories and environment cleanup to avoid side effects.

### Key Data Structures

```janet
# Config format (JSON on disk, struct in code)
{:vendor "groq"
 :model "groq/compound-mini"
 :source "Korean"
 :target "English"
 :persona "default"
 :temperature 0.3
 :copy true
 :api-key "optional-key-here"}

# Parsed CLI args (merged config + args)
{:text "안녕하세요"
 :source "Korean"
 :target "English"
 :persona "default"
 :temperature 0.3
 :copy true
 :vendor "groq"
 :model "groq/compound-mini"
 :api-key "..."
 :show-config false
 :show-prompt false
 :show-persona false}

# API request payload
{:model "groq/compound-mini"
 :messages [{:role "system" :content "..."}
            {:role "user" :content "Translate from Korean to English: ..."}]
 :temperature 0.3}
```

### Module Dependencies

```
main.janet
├── cli.janet (argument parsing)
├── config.janet (config file I/O)
│   └── prompt.janet (for DEFAULT_TEMPERATURE)
├── init.janet (initialization wizard)
│   └── config.janet
│   └── prompt.janet
├── prompt.janet (prompt generation)
└── vendor.janet (multi-vendor API abstraction)
```

Note: `main.janet` imports all modules and orchestrates the workflow. The `vendor.janet` module is self-contained with no dependencies. Other modules have minimal cross-dependencies.

### Documentation Standards
All functions follow [Janet docstring guidelines](https://janet-lang.org/docs/documentation.html):
- Use triple backticks (`` ` ``) for multi-line docstrings
- Document arguments, returns, and examples
- Example format:
  ```janet
  (defn make-llm-request
    ``Send a translation request to configured LLM vendor.

    Supports multiple vendors through vendor.janet configuration.
    Implements retry logic with exponential backoff for network and server errors.

    Arguments:
    - text: The text to translate
    - api-key: API key for authentication
    - source-lang: Source language
    - target-lang: Target language
    - temperature: Temperature (0.0-2.0)
    - vendor: Vendor name (string or keyword, e.g., "groq", :openai)
    - model: Model name (e.g., "groq/compound-mini", "gpt-4o-mini")
    - persona: Optional persona keyword (default: :default)

    Returns:
    Translated text string, or nil on failure.

    Example:
      (make-llm-request "Hello" "key" "English" "Korean" 0.3 "groq" "groq/compound-mini")
      (make-llm-request "Hello" "key" "English" "Korean" 0.3 :anthropic "claude-4-5-haiku-20241022")
    ``
    [text api-key source-lang target-lang temperature vendor model &opt persona]
    ...)
  ```