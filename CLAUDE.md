# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

tsl-janet is a production-ready translation CLI tool built with Janet language using Groq's API. The tool interfaces with Groq's compound-mini model through their OpenAI-compatible endpoint to provide fast, accurate translations.

## Development Commands

### Testing
```bash
# Recommended: Run all tests with jpm
jpm test

# This will automatically run all tests in test/ directory:
# - test/test-basics.janet (7 tests)
# - test/test-main.janet (10 tests)

# Or run individual test files
janet test/test-basics.janet
janet test/test-main.janet

# Install test dependency (spork) if needed
jpm deps
```

**Expected output:**
```
running test/test-basics.janet ...
test suite test/test-basics.janet finished in 0.000 seconds - 7 of 7 tests passed.
running test/test-main.janet ...
test suite test/test-main.janet finished in 0.000 seconds - 10 of 10 tests passed.
All tests passed.
```

### Running the CLI
```bash
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

# With environment variable
GROQ_API_KEY=your-key janet src/main.janet "你好" -s Chinese -t English
```

## Environment Setup

**Required**: Set `GROQ_API_KEY` environment variable before running:
```bash
export GROQ_API_KEY="your-api-key-here"
```

Or create a `.env` file (already gitignored).

## API Integration Details

- **Base URL**: `https://api.groq.com/openai/v1`
- **Model**: `groq/compound-mini`
- **API Format**: OpenAI-compatible endpoint

## Testing Framework

Uses `spork/test` module with these key functions:
- `test/start-suite` and `test/end-suite` - Test suite lifecycle
- `test/assert` - Standard assertions with ✔/✘ output
- `test/assert-error` and `test/assert-no-error` - Error handling tests

Test structure validates:
- Environment variable access
- String operations for prompt handling
- Data structures for API payloads (structs for JSON)
- Array operations for message formatting

## Code Architecture

The project follows a clean, organized structure:

### Source Files
- `src/main.janet` - Main translation CLI entry point
  - `parse-args` - Parse command line flags (--source, --target, --temperature)
  - `make-groq-request` - Handles API calls to Groq with temperature
  - `print-usage` - Display usage information
  - `main` - Entry point function

- `src/prompt.janet` - Prompt and parameter management module
  - `DEFAULT_TEMPERATURE` - Constant (0.3 for translation)
  - `get-system-prompt` - Returns detailed translation guidelines
  - `build-messages` - Constructs system + user message array
  - `validate-temperature` - Validates temperature range (0.0-2.0)

### Test Files
- `test/test-basics.janet` - Basic functionality tests (7 tests)
- `test/test-main.janet` - Main translation feature tests (10 tests)

### Key Data Structures
- API payload format: `{:model "groq/compound-mini" :messages [...] :temperature 0.3}`
- Messages array: `[{:role "system" :content "..."} {:role "user" :content "..."}]`
  - System message: Detailed translation guidelines
  - User message: `"Translate from [source] to [target]: [text]"`
- Parsed args format: `{:text "..." :source "Korean" :target "English" :temperature 0.3}`
- Default values:
  - source: Korean
  - target: English
  - temperature: 0.3 (optimized for translation accuracy)

### Documentation Standards
All functions follow [Janet docstring guidelines](https://janet-lang.org/docs/documentation.html):
- Use backticks (`` ` ``) for multi-line docstrings
- Document arguments and return values
- Include usage examples where helpful