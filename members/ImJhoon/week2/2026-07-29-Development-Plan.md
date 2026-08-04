# 2026-07-29 개발 계획

내일 진행할 작업은 다음 세 가지입니다.

1. 회원가입 기능 구현
2. Spring Security 개념 학습 및 프로젝트 설정
3. Swagger/OpenAPI 개념 학습 및 프로젝트 설정

단순히 설정 파일만 복사하지 않고, 각 기술이 왜 필요한지 이해한 뒤 현재 영화 예매 프로젝트에 적용하는 것을 목표로 합니다.

---

## 1. 내일의 최종 목표

하루를 마쳤을 때 다음 상태가 되면 좋습니다.

- `POST /api/v1/auth/signup` 회원가입 API가 동작한다.
- 비밀번호가 평문이 아닌 암호화된 형태로 저장된다.
- 중복 이메일, 닉네임, 전화번호를 검증한다.
- 공개 API와 인증 필요 API를 Spring Security에서 구분한다.
- Swagger UI에서 API 명세를 확인하고 회원가입 요청을 실행할 수 있다.
- 회원가입의 정상·실패 상황을 테스트로 검증한다.

---

## 2. 권장 진행 순서

회원가입은 비밀번호 암호화가 필요하므로 Spring Security의 최소 개념과 `PasswordEncoder`를 먼저 이해해야 합니다.

```text
API 명세 확인
    ↓
Spring Security 기본 개념 학습
    ↓
최소 Security 설정 및 PasswordEncoder 등록
    ↓
회원가입 기능 구현
    ↓
회원가입 테스트
    ↓
Swagger/OpenAPI 학습 및 설정
    ↓
Swagger UI에서 최종 확인
```

---

## 3. 시작 전 확인

현재 프로젝트에는 필요한 기본 의존성이 이미 들어 있습니다.

```gradle
implementation 'org.springframework.boot:spring-boot-starter-security'
implementation 'org.springframework.boot:spring-boot-starter-validation'
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:3.0.2'
```

각 의존성의 역할은 다음과 같습니다.

| 의존성 | 역할 |
|---|---|
| Spring Security | 인증, 권한 확인, 비밀번호 암호화 |
| Validation | 이메일 형식, 필수값, 문자열 길이 등 요청값 검증 |
| springdoc-openapi | 코드에서 OpenAPI 명세를 만들고 Swagger UI 제공 |

새 의존성을 추가하기 전에 현재 의존성으로 필요한 기능을 구현할 수 있는지 먼저 확인합니다.

---

## 4. Spring Security 학습 및 설정

### 4.1 먼저 이해할 개념

- 인증(Authentication): 요청한 사용자가 누구인지 확인하는 과정
- 권한 확인(Authorization): 해당 사용자가 요청을 수행할 수 있는지 확인하는 과정
- Security Filter Chain: Controller에 도달하기 전에 요청을 검사하는 필터 흐름
- `PasswordEncoder`: 비밀번호를 안전한 해시 형태로 변환하고 비교하는 객체
- 서버 세션과 세션 쿠키를 이용한 인증 흐름
- 쿠키 기반 인증에서 CSRF 보호가 필요한 이유
- CORS가 무엇이고 브라우저 요청에서 왜 필요한지

### 4.2 프로젝트에 필요한 최소 설정

`global/security` 또는 `global/config` 아래에 Security 설정을 작성합니다.

내일 설정할 최소 범위는 다음과 같습니다.

- `SecurityFilterChain` Bean 등록
- `PasswordEncoder` Bean 등록
- 회원가입과 로그인 API 공개
- Swagger 문서 경로 공개
- 영화, 영화관, 상영 일정 조회 API 공개
- 사용자 정보, 예매, 결제 API는 인증 필요 상태로 구분
- 필요할 때만 세션을 생성하고 쿠키 기반 인증에 CSRF 보호 적용

공개 대상 예시는 다음과 같습니다.

```text
/api/v1/auth/signup
/api/v1/auth/login
/api/v1/auth/check-email
/api/v1/auth/check-nickname
/api/v1/movies/**
/api/v1/cinemas/**
/api/v1/screenings/**
/swagger-ui/**
/v3/api-docs/**
```

로그인 구현 시에는 인증 성공 정보를 `SecurityContext`에 저장하고, 이를 서버 세션에 보관하여 이후 요청의 세션 쿠키로 사용자를 인증합니다. 로그아웃 시에는 서버 세션을 무효화하고 세션 쿠키를 제거합니다.

### 4.3 Security 완료 기준

- 애플리케이션이 정상 실행된다.
- 회원가입 API에 로그인 없이 접근할 수 있다.
- 인증 필요 경로에 인증 없이 접근하면 차단된다.
- Swagger UI와 OpenAPI 문서 경로가 Security에 의해 차단되지 않는다.
- `PasswordEncoder`를 Service에 주입할 수 있다.

---

## 5. 회원가입 기능 구현

대상 API는 다음과 같습니다.

```http
POST /api/v1/auth/signup
```

요청 필드는 기존 API 명세를 따릅니다.

```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "password_confirm": "Password123!",
  "nickname": "cinemaUser",
  "name": "홍길동",
  "phone": "010-1234-5678"
}
```

### 5.1 구현할 클래스

아래 이름은 초안이며 프로젝트 컨벤션에 맞게 조정할 수 있습니다.

```text
auth
├─ controller
│  └─ AuthController.java
├─ dto
│  ├─ SignupRequest.java
│  └─ SignupResponse.java
└─ service
   └─ AuthService.java

user
└─ repository
   └─ UserRepository.java
```

역할은 다음과 같습니다.

- `SignupRequest`: 회원가입 요청값과 입력 형식 검증
- `SignupResponse`: 클라이언트에 반환할 안전한 사용자 정보
- `AuthController`: HTTP 회원가입 요청을 받음
- `AuthService`: 중복 확인, 비밀번호 암호화, 사용자 저장
- `UserRepository`: 사용자 조회 및 저장

### 5.2 요청값 검증

확인할 항목은 다음과 같습니다.

- 이메일이 비어 있지 않은가?
- 이메일 형식이 올바른가?
- 이메일이 이미 존재하는가?
- 비밀번호가 정한 복잡도 조건을 만족하는가?
- `password`와 `password_confirm`이 일치하는가?
- 닉네임이 비어 있지 않고 길이 조건을 만족하는가?
- 닉네임이 이미 존재하는가?
- 이름과 전화번호가 비어 있지 않은가?

단순 형식 검증과 비즈니스 검증을 구분합니다.

```text
DTO Validation
├─ 필수값
├─ 이메일 형식
└─ 문자열 길이

Service 검증
├─ 이메일 중복
├─ 닉네임 중복
└─ 비밀번호 확인 일치
```

### 5.3 비밀번호 처리

비밀번호를 절대 평문으로 저장하지 않습니다.

```text
사용자 입력 비밀번호
    ↓
PasswordEncoder.encode(...)
    ↓
암호화된 해시
    ↓
users.password에 저장
```

`password_confirm`은 비밀번호 일치 확인에만 사용하며 데이터베이스에는 저장하지 않습니다.

### 5.4 응답 처리

응답에 다음 정보를 포함하지 않습니다.

- 비밀번호
- 비밀번호 확인값
- 내부 보안 정보

성공 응답은 공통 응답 규칙을 따릅니다.

```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "email": "user@example.com",
    "nickname": "cinemaUser"
  }
}
```

회원가입으로 데이터가 생성되므로 HTTP 상태 코드는 `201 Created`를 사용합니다.

### 5.5 예외 처리

최소한 다음 실패 상황을 구분합니다.

| 상황 | 권장 상태 코드 | 오류 코드 예시 |
|---|---:|---|
| 잘못된 입력값 | `400` | `INVALID_SIGNUP_INPUT` |
| 비밀번호 확인 불일치 | `400` | `PASSWORD_CONFIRM_MISMATCH` |
| 이메일 중복 | `409` | `EMAIL_ALREADY_EXISTS` |
| 닉네임 중복 | `409` | `NICKNAME_ALREADY_EXISTS` |

동시 요청에서는 사전 중복 조회를 모두 통과할 수 있으므로 데이터베이스의 UNIQUE 제약 조건도 유지해야 합니다.

### 5.6 회원가입 완료 기준

- 정상 요청에 `201 Created`를 반환한다.
- 비밀번호가 암호화되어 저장된다.
- `password_confirm`은 저장되지 않는다.
- 기본 역할이 `USER`로 저장된다.
- `createdAt`, `updatedAt`이 JPA Auditing으로 자동 입력된다.
- 이메일, 닉네임, 전화번호 중복 요청을 거절한다.
- 응답에 비밀번호가 노출되지 않는다.

---

## 6. 회원가입 테스트

구현만 하고 끝내지 않고 최소한 다음 상황을 검증합니다.

### Service 테스트

- 정상 회원가입
- 이메일 중복 실패
- 닉네임 중복 실패
- 비밀번호 확인 불일치
- 저장되는 비밀번호가 원문과 다른지 확인
- 저장되는 비밀번호를 `PasswordEncoder.matches()`로 검증

### Controller 테스트

- 올바른 요청에 `201` 반환
- 잘못된 이메일에 `400` 반환
- 필수값 누락에 `400` 반환
- 응답 JSON에 비밀번호가 없는지 확인

### Security 테스트

- 인증 없이 회원가입 API 접근 가능
- 인증 없이 보호된 API 접근 시 차단
- Swagger 경로 접근 가능

---

## 7. Swagger와 OpenAPI 학습 및 설정

### 7.1 용어 구분

- OpenAPI: REST API의 주소, 요청, 응답 등을 표현하는 표준 명세
- Swagger UI: OpenAPI 명세를 사람이 확인하고 API를 실행해볼 수 있는 화면
- springdoc-openapi: Spring Controller 코드를 분석하여 OpenAPI 명세를 생성하는 라이브러리

Swagger와 OpenAPI를 같은 의미로 부르는 경우가 많지만 엄밀하게는 역할이 다릅니다.

### 7.2 학습할 내용

- OpenAPI 문서가 생성되는 원리
- Controller와 DTO가 문서에 반영되는 방식
- `@Operation`, `@Schema`, `@Parameter`의 역할
- 성공 응답과 오류 응답을 문서에 표현하는 방법
- Swagger UI에서 세션 쿠키와 CSRF 토큰을 사용해 상태 변경 API를 실행하는 방법

### 7.3 프로젝트 설정

확인할 기본 주소는 다음과 같습니다.

```text
Swagger UI: /swagger-ui/index.html
OpenAPI JSON: /v3/api-docs
```

진행할 작업은 다음과 같습니다.

- 애플리케이션 제목, 설명, 버전 설정
- Swagger UI 접속 확인
- 회원가입 API가 문서에 표시되는지 확인
- 요청 DTO의 필드와 검증 조건 확인
- 성공 및 주요 오류 응답 설명 추가
- Security에서 Swagger 관련 경로 `permitAll` 처리

### 7.4 Swagger 완료 기준

- Swagger UI 화면이 열린다.
- 회원가입 API가 표시된다.
- 요청 JSON 예시를 확인할 수 있다.
- Swagger UI에서 회원가입 API를 실행할 수 있다.
- 실제 응답 상태 코드와 문서 내용이 일치한다.

---

## 8. 작업하면서 주의할 점

- Controller에 중복 검사나 비밀번호 암호화 로직을 작성하지 않습니다.
- 요청 DTO와 엔티티를 분리합니다.
- `User` 엔티티를 API 응답으로 직접 반환하지 않습니다.
- 비밀번호, 세션 ID, CSRF 토큰을 로그로 출력하지 않습니다.
- Security 오류를 해결하기 위해 모든 경로를 무조건 `permitAll`로 열지 않습니다.
- CSRF를 이유 없이 비활성화하지 않고 현재 인증 방식과의 관계를 먼저 이해합니다.
- Swagger 문서가 실제 API 동작과 다르지 않은지 확인합니다.
- 기능 구현 후 반드시 테스트를 실행합니다.

---

## 9. 내일 체크리스트

### 시작

- [ ] `API-Specification.md`의 회원가입 항목 다시 읽기
- [ ] 현재 `User` 엔티티와 `users` 테이블 확인
- [ ] 작업용 브랜치 또는 현재 Git 상태 확인

### Spring Security

- [ ] 인증과 권한의 차이 정리
- [ ] Security Filter Chain의 역할 정리
- [ ] `SecurityFilterChain` Bean 작성
- [ ] `PasswordEncoder` Bean 작성
- [ ] 공개 경로와 보호 경로 구분
- [ ] CSRF 및 세션 정책 결정

### 회원가입

- [ ] `SignupRequest` 작성
- [ ] `SignupResponse` 작성
- [ ] `UserRepository` 작성
- [ ] `AuthService` 작성
- [ ] 이메일 중복 검증
- [ ] 닉네임 중복 검증
- [ ] 비밀번호 확인 일치 검증
- [ ] 비밀번호 암호화
- [ ] `AuthController` 작성
- [ ] `POST /api/v1/auth/signup` 연결
- [ ] 공통 성공·오류 응답 적용

### 테스트

- [ ] 정상 회원가입 테스트
- [ ] 이메일 중복 테스트
- [ ] 닉네임 중복 테스트
- [ ] 비밀번호 불일치 테스트
- [ ] Validation 실패 테스트
- [ ] Security 공개·보호 경로 테스트

### Swagger/OpenAPI

- [ ] OpenAPI와 Swagger UI 차이 정리
- [ ] Swagger UI 접속 확인
- [ ] OpenAPI 기본 정보 설정
- [ ] Security에서 문서 경로 허용
- [ ] 회원가입 API 설명 추가
- [ ] Swagger UI에서 회원가입 요청 실행

### 마무리

- [ ] `./gradlew test` 또는 `.\gradlew.bat test` 실행
- [ ] 비밀번호가 로그와 응답에 노출되지 않는지 확인
- [ ] API 명세와 실제 구현 비교
- [ ] 학습한 내용 문서에 추가
- [ ] 변경 유형별로 커밋 정리

---

## 10. 시간이 부족할 때의 우선순위

하루 안에 모든 내용을 완료하기 어렵다면 다음 순서로 진행합니다.

1. Spring Security 기본 개념과 `PasswordEncoder`
2. 회원가입 정상 흐름 구현
3. 중복·Validation·비밀번호 테스트
4. 공개 경로와 보호 경로 설정
5. Swagger UI 접속 및 회원가입 API 확인
6. Swagger 상세 문서화
7. 세션 로그인·로그아웃 및 세션 고정 공격 방어 구현

세션 인증 구현 전에도 안전한 회원가입과 기본 Security 설정을 먼저 완성하는 것이 중요합니다.

---

## 11. 내일 기록할 내용

작업을 마친 뒤 다음 질문에 답을 적어봅니다.

- Spring Security가 요청을 검사하는 위치는 어디인가?
- 인증과 권한 확인은 어떻게 다른가?
- 비밀번호를 암호화해서 저장해야 하는 이유는 무엇인가?
- DTO와 Entity를 분리한 이유는 무엇인가?
- 이메일 중복 조회만으로 동시 요청을 완전히 막을 수 없는 이유는 무엇인가?
- OpenAPI와 Swagger UI는 어떻게 다른가?
- Swagger 경로를 Security에서 허용해야 하는 이유는 무엇인가?
- 내일 구현하면서 가장 어려웠던 부분은 무엇인가?
