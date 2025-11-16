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

# 4. 번역 실행
janet src/main.janet "Hello world"
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
# 한국어로 번역 (기본값)
janet src/main.janet "Hello world"

# 다른 언어로 번역
janet src/main.janet "Hello world" English
janet src/main.janet "Bonjour" Korean
janet src/main.janet "你好" Spanish
janet src/main.janet "こんにちは" French
```

### 사용 형식

```
janet src/main.janet <텍스트> [목표언어]
```

**인자:**
- `<텍스트>`: 번역할 텍스트 (필수)
- `[목표언어]`: 번역할 언어 (선택, 기본값: Korean)

### 예제 출력

```bash
$ export GROQ_API_KEY="gsk_..."
$ janet src/main.janet "Hello world"
Translating to Korean...

Translation:
안녕하세요, 세계!
```

```bash
$ janet src/main.janet "안녕하세요" English
Translating to English...

Translation:
Hello
```

## API 정보 (API Information)

- **Provider**: [Groq](https://groq.com)
- **Base URL**: `https://api.groq.com/openai/v1`
- **Model**: [compound-mini](https://console.groq.com/docs/compound/systems/compound-mini)
- **Endpoint**: `/chat/completions` (OpenAI-compatible)

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
# 전체 테스트 실행
janet test/test-basics.janet
janet test/test-main.janet

# 또는 jpm을 통해 실행
jpm test
```

**테스트 커버리지:**
- ✅ 환경 변수 처리
- ✅ GROQ_API_KEY 검증
- ✅ API 페이로드 구조
- ✅ JSON 인코딩/디코딩
- ✅ HTTP 헤더 구성
- ✅ 문자열 및 데이터 구조 작업
- ✅ 에러 핸들링

### 테스트 결과

```
test-basics.janet: 7/7 통과 ✅
test-main.janet:  10/10 통과 ✅
```

## 프로젝트 구조 (Project Structure)

```
tsl-janet/
├── src/
│   └── main.janet      # 번역 CLI 도구 (메인)
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
