# TSL-Janet 기능 개선 로드맵

이 문서는 `tsl` (aliased to `sl`) 도구의 기능 확장 및 개선을 위한 할 일 목록을 담고 있습니다.

## 테스트 및 문서화
각 Phase 완료 후 다음 항목 테스트 및 문서화

## 기존 기능 유지 및 호환성
- [ ] CLI 인자 우선순위 처리
  - `CLI 인자` > `설정 파일` > `기본값` 순서로 동작 보장
  - 기존 명령어 (`tsl "text"`, `tsl -t French "text"`)가 변경 없이 작동하도록 유지
- [ ] 클립보드 및 출력 제어
  - 설정 파일에 `copy: true/false` 옵션 추가하여 기본 동작 제어 가능하게 변경

## Phase 1: 설정 관리 시스템 (Configuration Management)
- [ ] 설정 파일 구조 설계
  - JSON 형식 사용 (`XDG_CONFIG_HOME/tsl/config.json`): janet 은 아직 yaml 을 지원하는 패키지가 없음
  - 저장 항목: 선택된 벤더, 모델, 기본 소스 언어, 기본 타겟 언어, API 키(선택적/환경변수 우선)
  - 모델 특성을 지원하는 경우 사용할 수 있는 temporature 기본값 설정
- [ ] 설정 로드/저장 모듈 구현
  - 앱 시작 시 설정 파일 존재 여부 확인
  - 설정 파일이 있을 경우 로드
  - 설정 파일이 없을 경우 초기화 마법사 (--init) 실행 제안
  - 사용할 벤더 및 모델이 없을 경우 환경 변수에서 API 키 감지
  - 사용할 수 있는 API 키가 감지되지 않을 경우 사용자에게 알림 후 프로그램 종료
  - 설정 파일이 없을 경우 기본값(Groq, Korean -> English) 사용
  - `src/config.janet` 모듈에서 관리
  - 설정을 마치면 화면에 로그를 출력하고 종료.

## Phase 2: 초기화 마법사 (`--init`)
- [ ] 환경 스캔 및 벤더 매핑
  - env 에 GEMINI_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, MISTRAL_API_KEY,
    DEEPSEEK_API_KEY, OPENROUTER_API_KEY, CEREBRAS_API_KEY, GROQ_API_KEY 가 있는 경우 선택할 수 있도록 제안
  - 시스템 환경 변수에서 주요 벤더 API 키 감지
    - `GROQ_API_KEY` -> Groq
    - `OPENAI_API_KEY` -> OpenAI
    - `ANTHROPIC_API_KEY` -> Anthropic
    - `DEEPSEEK_API_KEY` -> DeepSeek
  - 감지된 키를 기반으로 사용 가능한 벤더 목록 제안
- [ ] 대화형 설정 인터페이스
  - 벤더 선택 프롬프트
  - 벤더별 모델 목록 제공 및 선택 (예: Groq 선택 시 `llama-3.1-8b`, `mixtral-8x7b` 등)
  - 벤더가 제공하는 목록은 하드코딩 또는 외부 소스에서 동적으로 로드
  - 기본 언어 설정 (Source / Target)
  - 설정 결과와 나머지 기본 세팅을 `XDG_CONFIG_HOME/tsl/config.json` 파일 저장

## Phase 3: 페르소나 구현
- [ ] 페르소나 설정 기능 추가
  - 사전 정의된 페르소나 목록 제공 (예: 번역가, 요약가, 코딩 도우미 등)
  - prompt.janet 에 페르소나별 프롬프트 템플릿 저장
  - `--persona <persona_name>` 플래그 구현
  - 선택한 페르소나에 따라 프롬프트 템플릿 자동 변경

## Phase 4: 설정 상태 확인
- [ ] `--show-config` 플래그 구현
  - 현재 설정된 벤더, 모델, 기본 소스 언어, 기본 타겟 언어 출력
  - API 키는 보안상 출력하지 않음
- [ ] `--show-prompt` 플래그 구현
  - 현재 설정된 프롬프트 템플릿 출력
- [ ] `--show-persona` 플래그 구현
  - 현재 설정된 페르소나 출력

## Phase 5: 예외 상황 처리 개선
- [ ] 설정 파일 읽기/쓰기 오류 처리
  - 파일 권한 문제, 디스크 공간 부족 등 예외 상황 처리
  - 설정 파일이 없는 경우 --init 과정으로 안내
  - 사용자에게 명확한 오류 메시지 제공
- [ ] env 에 아무런 키도 없는 경우 --init 과정에서 해당 프로바이더의 키를 받아 저장하도록 개선
  - API 키 입력 시 빈 값 검증 및 최소 길이 확인 (20자)
  - 최대 3회 재시도
- [ ] 저장된 api key 가 있는 경우 사용하도록 코드 개선
  - 벤더별 환경변수 동적 매핑
  - 우선순위: 환경변수 > config 파일
- [ ] 네트워크 오류 처리
  - API 요청 실패 시 사용자에게 명확한 오류 메시지 제공
  - 재시도 로직 구현 (최대 3회, 지수 백오프)
  - HTTP 상태 코드 확인 및 분류

## Phase 6: 네트워크 서비스 개선 및 오류 처리
- [ ] `net.janet` 모듈 활용
  - main.janet 의 네트워크 요청 코드를 `http-client.janet` 기반으로 리팩토링
  - 비동기 요청 및 응답 처리 개선
- [ ] 잘못된 API 키 처리
  - 인증 실패 시 사용자에게 알림 및 설정 파일 재설정 안내
  - HTTP 401/403 오류 구분 처리
  - Rate limit (429) 및 서버 오류 (5xx) 별도 안내

## Phase 7: 멀티 벤더 지원 구조 개선
- [ ] API 요청 추상화
  - 현재 `make-groq-request`를 범용 `make-llm-request`로 리팩토링
  - 벤더별 엔드포인트 및 헤더 처리 로직 분리
  - OpenAI 호환 인터페이스(Groq, DeepSeek 등)와 독자 규격(Anthropic) 구분 처리
- [ ] 동적 모델 바인딩
  - 설정 파일 또는 CLI 인자에서 지정한 모델을 API 요청에 반영

## Phase 8: joyframework/http 모듈 적용
- [ ] `joyframework/http` 모듈로 네트워크 요청 리팩토링
  - `curl` 기반 코드를 `joyframework/http`로 전환
  - 요청 생성, 헤더 설정, 응답 처리 로직 개선
  - README 및 문서화 업데이트
- [ ] 온보딩 프로세스 및 각종 화면 출력에 유니코드 이모지 적용
