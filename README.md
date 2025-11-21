# tsl-janet

Janet 언어로 작성된 다중 LLM 벤더 지원 텍스트 번역 CLI 도구

A text translation CLI tool built with Janet language, supporting multiple LLM vendors.

## 프로젝트 개요 (Overview)

`tsl-janet`은 Groq, OpenAI, Anthropic, Gemini 등 다양한 LLM 벤더를 지원하는 텍스트 번역 CLI 도구입니다. Janet 언어의 간결함과 최신 LLM의 강력한 성능을 결합했습니다.

## 요구사항 (Requirements)

- [Janet](https://janet-lang.org/) 1.0 이상
- [JPM](https://github.com/janet-lang/jpm) (Janet Package Manager)
- [spork](https://github.com/janet-lang/spork) (자동 설치됨)
- [joyframework/http](https://github.com/joy-framework/http) (자동 설치됨)
- **libcurl 개발 라이브러리** (시스템 의존성, 아래 설치 가이드 참조)
- LLM API 키 (Groq, OpenAI, Anthropic, Gemini 등)

## 빠른 시작 (Quick Start)

```bash
# 1. 저장소 클론
git clone <repository-url>
cd tsl-janet

# 2. 의존성 설치
jpm deps

# 3. API 키 설정
export GROQ_API_KEY="your-api-key-here"

# 4. 번역 실행 (Korean → English 기본값)
tsl "안녕하세요"
```

## 설치 (Installation)

### 의존성 설치

```bash
# spork 및 필요한 패키지 설치
jpm deps
```

### 시스템 의존성 설치

joyframework/http 모듈은 libcurl 개발 라이브러리가 필요합니다:

**macOS:**
```bash
# Homebrew 사용 (보통 이미 설치되어 있음)
brew install curl
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install libcurl4-openssl-dev
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install libcurl-devel
# 또는
sudo yum install libcurl-devel
```

### 환경 변수 설정

사용하려는 벤더의 API 키를 환경 변수로 설정합니다:

```bash
# Groq (기본값)
export GROQ_API_KEY="your-groq-key"

# 또는 다른 벤더
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export GEMINI_API_KEY="your-gemini-key"
```

영구적으로 설정하려면 `.bashrc`, `.zshrc` 또는 `.env` 파일에 추가:

```bash
# ~/.bashrc 또는 ~/.zshrc
export GROQ_API_KEY="your-groq-key"
export OPENAI_API_KEY="your-openai-key"
```

## 사용 방법 (Usage)

### 기본 번역

```bash
# 기본값 사용 (Korean → English)
tsl "안녕하세요"

# Target 언어 지정
tsl "안녕하세요" --target Spanish
tsl "안녕하세요" -t French

# Source와 Target 모두 지정
tsl "Hello world" --source English --target Korean
tsl "Bonjour" -s French -t Korean
tsl "你好" --source Chinese --target English

# Temperature 조정 (창의성 vs 정확성)
tsl "안녕하세요" --temperature 0.1  # 더 정확하고 일관적
tsl "Hello" -s English -t Korean -T 0.7  # 더 창의적

# 클립보드 복사 비활성화
tsl "Hello" --no-copy  # 클립보드에 복사하지 않음

# 페르소나 사용
tsl "코드 작성" --persona programming
tsl "연구 논문" --persona research

# 벤더 및 모델 지정
tsl "Hello" --vendor openai --model gpt-4o-mini
tsl "Hello" --vendor anthropic --model claude-3-5-sonnet-20241022
tsl "Hello" --vendor gemini --model gemini-1.5-flash

# 설정 확인
tsl --show-config      # 현재 설정 출력
tsl --show-prompt      # 현재 프롬프트 출력
tsl --show-persona     # 현재 페르소나 출력

```

### 사용 형식

```
tsl <텍스트> [옵션]
```

**인자:**
- `<텍스트>`: 번역할 텍스트 (필수)

**옵션:**
- `-s, --source <언어>`: 원본 언어 (기본값: Korean)
- `-t, --target <언어>`: 대상 언어 (기본값: English)
- `-T, --temperature <숫자>`: Temperature 0.0-2.0 (기본값: 0.3)
  - 낮은 값 (0.0-0.3): 더 정확하고 일관적인 번역
  - 중간 값 (0.3-0.7): 균형잡힌 번역
  - 높은 값 (0.7-2.0): 더 창의적이고 다양한 표현
- `-v, --vendor <이름>`: LLM 벤더 (groq, openai, anthropic, gemini, deepseek, cerebras, openrouter, mistral)
- `-m, --model <이름>`: 사용할 모델명
- `-p, --persona <이름>`: 페르소나 선택 (default, programming, research, review)
- `--no-copy`: 자동 클립보드 복사 비활성화 (기본값: 활성화)
- `--init`: 설정 마법사 실행
- `--show-config`: 현재 설정 정보 출력
- `--show-prompt`: 현재 프롬프트 템플릿 출력
- `--show-persona`: 현재 페르소나 정보 출력

### 예제 출력

```bash
$ export GROQ_API_KEY="gsk_..."
$ tsl "안녕하세요"
Translating from Korean to English...
Temperature: 0.3

Translation:
Hello
📋 Copied to clipboard
```

```bash
$ tsl "Hello world" --source English --target Korean
Translating from English to Korean...
Temperature: 0.3

Translation:
안녕하세요, 세계!
📋 Copied to clipboard
```

```bash
$ tsl "Bonjour" -s French -t Spanish -T 0.5
Translating from French to Spanish...
Temperature: 0.5

Translation:
Hola
📋 Copied to clipboard
```

```bash
$ tsl "Hello" --no-copy
Translating from Korean to English...
Temperature: 0.3

Translation:
Hello
# 클립보드 복사 안 됨
```

## 지원하는 벤더 (Supported Vendors)

| Vendor | Env Variable | Default Model |
|--------|--------------|---------------|
| **Groq** | `GROQ_API_KEY` | `groq/compound-mini` |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-4o-mini` |
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-3-5-sonnet-20241022` |
| **Gemini** | `GEMINI_API_KEY` | `gemini-1.5-flash` |
| **DeepSeek** | `DEEPSEEK_API_KEY` | `deepseek-chat` |
| **Cerebras** | `CEREBRAS_API_KEY` | `llama3.1-8b` |
| **OpenRouter** | `OPENROUTER_API_KEY` | `openai/gpt-3.5-turbo` |
| **Mistral** | `MISTRAL_API_KEY` | `mistral-small-latest` |


## 개발 (Development)

### JPM 명령어

```bash
# 의존성 설치
jpm deps

# 테스트 실행
jpm test

# 빌드 (해당하는 경우)
jpm build

# 프로젝트 정리
jpm clean
```

### 테스트

프로젝트는 [spork/test](https://janet-lang.org/spork/api/test.html)를 사용합니다.

```bash
# 권장: jpm을 통한 전체 테스트 실행
jpm test

# 또는 개별 테스트 파일 실행
janet test/test-basics.janet
janet test/test-main.janet
```

**jpm test 출력 예제:**
```
$ jpm test
running test/test-basics.janet ...
test suite test/test-basics.janet finished in 0.000 seconds - 7 of 7 tests passed.
running test/test-main.janet ...
test suite test/test-main.janet finished in 0.000 seconds - 10 of 10 tests passed.
All tests passed.
```

## 프로젝트 구조 (Project Structure)

```
tsl-janet/
├── src/
│   ├── main.janet      # 번역 CLI 도구 (메인)
│   └── prompt.janet    # 프롬프트 및 파라미터 관리 모듈
├── test/
│   ├── test-basics.janet # 기본 테스트 스위트
│   └── test-main.janet   # 메인 기능 테스트 스위트
├── project.janet       # JPM 프로젝트 설정
├── .gitignore          # Git 제외 파일
├── CLAUDE.md           # Claude Code 가이드
└── README.md           # 이 문서
```

## 코드 문서화 (Documentation)

모든 함수는 Janet 공식 [문서화 가이드라인](https://janet-lang.org/docs/documentation.html)을 따릅니다:

```janet
(defn make-llm-request
  ``Send a translation request to configured LLM vendor.

  Arguments:
  - text: The text string to translate
  - api-key: API key for authentication
  - source-lang: Source language
  - target-lang: Target language
  - temperature: Temperature for generation (0.0-2.0)
  - vendor: Vendor name (e.g., "groq", "openai", "anthropic")
  - model: Model name

  Returns:
  The translated text as a string, or nil if fails.
  ``
  [text api-key source-lang target-lang temperature vendor model &opt persona]
  ...)
```

## 향후 계획 (Roadmap)

- [x] 프로덕션급 번역 CLI 도구
- [x] 설정 파일 지원 (XDG_CONFIG_HOME/tsl/config.json)
- [x] 초기화 마법사 (--init)
- [x] 페르소나 시스템
- [x] 설정 상태 확인 플래그 (--show-config, --show-prompt, --show-persona)
- [x] 다중 모델 지원 (llama-3.3-70b-versatile, mixtral 등)
- [ ] 스트리밍 응답 지원
- [ ] 대화 히스토리 관리
- [ ] 일괄 번역 기능

## 기여 (Contributing)

기여를 환영합니다! Pull Request를 보내주세요.

## 라이선스 (License)

MIT License

## 관련 링크 (Links)

- [Janet Language](https://janet-lang.org/)
- [spork Library](https://github.com/janet-lang/spork)
- [joyframework/http Library](https://github.com/joy-framework/http)
- [Groq API Documentation](https://console.groq.com/docs)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic API Documentation](https://docs.anthropic.com)
- [Google Gemini API Documentation](https://ai.google.dev/docs)
