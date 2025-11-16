# tsl-janet

Janet 언어로 작성된 Groq API 기반 텍스트 번역 CLI 도구

A text translation CLI tool built with Janet language, powered by Groq API.

## 프로젝트 개요 (Overview)

`tsl-janet`은 Groq의 compound-mini 모델을 사용하여 텍스트를 번역하는 프로덕션급 CLI 도구입니다. Janet 언어의 간결함과 Groq API의 빠른 응답 속도를 결합했습니다.

## 요구사항 (Requirements)

- [Janet](https://janet-lang.org/) 1.0 이상
- [JPM](https://github.com/janet-lang/jpm) (Janet Package Manager)
- [spork](https://github.com/janet-lang/spork) (자동 설치됨)
- Groq API 키 ([console.groq.com](https://console.groq.com)에서 발급)

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
janet src/main.janet "안녕하세요"
```

## 설치 (Installation)

### 의존성 설치

```bash
# spork 및 필요한 패키지 설치
jpm deps

# 또는 수동으로 spork 설치
jpm install spork
```

### 환경 변수 설정

Groq API 키를 환경 변수로 설정합니다:

```bash
export GROQ_API_KEY="your-api-key-here"
```

영구적으로 설정하려면 `.bashrc`, `.zshrc` 또는 `.env` 파일에 추가:

```bash
# ~/.bashrc 또는 ~/.zshrc
export GROQ_API_KEY="your-api-key-here"
```

## 사용 방법 (Usage)

### 기본 번역

```bash
# 기본값 사용 (Korean → English)
janet src/main.janet "안녕하세요"

# Target 언어 지정
janet src/main.janet "안녕하세요" --target Spanish
janet src/main.janet "안녕하세요" -t French

# Source와 Target 모두 지정
janet src/main.janet "Hello world" --source English --target Korean
janet src/main.janet "Bonjour" -s French -t Korean
janet src/main.janet "你好" --source Chinese --target English

# Temperature 조정 (창의성 vs 정확성)
janet src/main.janet "안녕하세요" --temperature 0.1  # 더 정확하고 일관적
janet src/main.janet "Hello" -s English -t Korean -T 0.7  # 더 창의적
```

### 사용 형식

```
janet src/main.janet <텍스트> [옵션]
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

### 예제 출력

```bash
$ export GROQ_API_KEY="gsk_..."
$ janet src/main.janet "안녕하세요"
Translating from Korean to English...
Temperature: 0.3

Translation:
Hello
```

```bash
$ janet src/main.janet "Hello world" --source English --target Korean
Translating from English to Korean...
Temperature: 0.3

Translation:
안녕하세요, 세계!
```

```bash
$ janet src/main.janet "Bonjour" -s French -t Spanish -T 0.5
Translating from French to Spanish...
Temperature: 0.5

Translation:
Hola
```

## API 정보 (API Information)

- **Provider**: [Groq](https://groq.com)
- **Base URL**: `https://api.groq.com/openai/v1`
- **Model**: `groq/compound-mini`
- **Endpoint**: `/chat/completions` (OpenAI-compatible)
- **Default Temperature**: 0.3 (optimized for translation accuracy)
- **System Prompt**: Detailed translation guidelines included

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

**테스트 커버리지:**
- ✅ 환경 변수 처리
- ✅ GROQ_API_KEY 검증
- ✅ API 페이로드 구조
- ✅ JSON 인코딩/디코딩
- ✅ HTTP 헤더 구성
- ✅ 문자열 및 데이터 구조 작업
- ✅ 에러 핸들링

**총 17개 테스트 모두 통과 ✅**

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
(defn make-groq-request
  ``Send a translation request to Groq API.

  Arguments:
  - text: The text string to translate
  - api-key: Groq API key for authentication
  - target-lang: Target language (default: "Korean")

  Returns:
  The translated text as a string, or nil if fails.
  ``
  [text api-key &opt target-lang]
  ...)
```

## 향후 계획 (Roadmap)

- [x] 프로덕션급 번역 CLI 도구
- [ ] 다중 모델 지원 (llama-3.3-70b-versatile, mixtral 등)
- [ ] 스트리밍 응답 지원
- [ ] 대화 히스토리 관리
- [ ] 설정 파일 지원 (.tslrc)
- [ ] 일괄 번역 기능

## 기여 (Contributing)

기여를 환영합니다! Pull Request를 보내주세요.

## 라이선스 (License)

MIT License

## 관련 링크 (Links)

- [Janet Language](https://janet-lang.org/)
- [Groq API Documentation](https://console.groq.com/docs)
- [compound-mini Model](https://console.groq.com/docs/compound/systems/compound-mini)
- [spork Library](https://github.com/janet-lang/spork)
