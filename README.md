# tsl-janet

Janet 언어로 작성된 Groq API 기반 텍스트 생성 CLI 도구

A text generation CLI tool built with Janet language, powered by Groq API.

## 요구사항 (Requirements)

- [Janet](https://janet-lang.org/) 설치 필요
- Groq API 키 ([console.groq.com](https://console.groq.com)에서 발급)

## 설치 (Installation)

```bash
git clone <repository-url>
cd tsl-janet
```

## 환경 변수 설정 (Environment Setup)

Groq API 키를 환경 변수로 설정합니다:

```bash
export GROQ_API_KEY="your-api-key-here"
```

또는 `.env` 파일을 생성하여 설정할 수 있습니다:

```
GROQ_API_KEY=your-api-key-here
```

## 사용 방법 (Usage)

```bash
janet main.janet "Your prompt here"
```

### 옵션 (Options)

- 기본 모델: `compound-mini`
- API Base URL: `https://api.groq.com/openai/v1`

## API 정보 (API Information)

- **Provider**: Groq
- **Base URL**: `https://api.groq.com/openai/v1`
- **Supported Model**: [compound-mini](https://console.groq.com/docs/compound/systems/compound-mini)

## 예제 (Example)

```bash
# 간단한 텍스트 생성
janet main.janet "Write a haiku about programming"

# 환경 변수와 함께 실행
GROQ_API_KEY=your-key janet main.janet "Explain quantum computing"
```

## 테스트 (Testing)

프로젝트는 [spork/test](https://janet-lang.org/spork/api/test.html)를 사용합니다.

### spork 설치

```bash
# spork가 설치되어 있지 않은 경우
jpm install spork
```

### 테스트 실행

```bash
janet test/test-main.janet
```

테스트는 다음을 검증합니다:
- 환경 변수 처리
- GROQ_API_KEY 설정 확인 (경고)
- 기본 문자열 및 데이터 구조 작업
- 에러 핸들링

## 프로젝트 구조 (Project Structure)

```
tsl-janet/
├── main.janet          # Main CLI entry point
├── project.janet       # Project configuration
├── test/
│   └── test-main.janet # Test suite
└── README.md          # This file
```

## 라이선스 (License)

MIT
