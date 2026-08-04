# [Week 2] 프로젝트 환경 구성, 엔터티 및 인증 API 구현

## 1. 과제 목표

Week 1의 영화 예매 서비스 모델링 결과를 실제 Spring Boot 프로젝트로 옮긴다. 각 스터디원은 독립된 작업 폴더에 실행 가능한 애플리케이션을 구성하고, JPA 엔터티와 JWT 기반 회원가입·로그인 API를 구현한다. 구현한 API는 Swagger UI에서 명세와 실행 결과를 확인할 수 있어야 한다.

이번 주차의 핵심은 기능 수를 늘리는 것이 아니라 다음 경계를 명확히 나누는 것이다.

- API 요청·응답 모델과 영속 엔터티의 분리
- Controller, Service, Repository의 책임 분리
- 비밀번호 원문과 인증 토큰 등 민감 정보의 안전한 처리
- Week 1 모델과 실제 데이터베이스 스키마의 일치

## 2. 기준 문서

구현 시 다음 문서를 기준으로 한다.

- `members/ImJhoon/week1/Project-Requirements.md`
- `members/ImJhoon/week1/Conceptual-Modeling.md`
- `members/ImJhoon/week1/Logical-Modeling.md`
- `members/ImJhoon/week1/API-Specification.md`
- `members/ImJhoon/week1/sql/DDL.sql`

기준 문서 사이에 차이가 있는 경우 엔터티와 제약조건은 `Logical-Modeling.md` 및 `DDL.sql`, 인증 API 경로와 필드는 `API-Specification.md`를 우선한다. 구현 과정에서 모델을 변경했다면 변경 이유와 영향을 개인 README에 기록한다.

## 3. 기술 제약

- Java 17
- Spring Boot 4.x
- Spring Web MVC
- Spring Data JPA
- Spring Security
- JWT 기반 Bearer 인증
- PostgreSQL
- springdoc-openapi 기반 Swagger/OpenAPI 문서화
- 빌드 도구는 Gradle 또는 Maven 중 하나를 선택한다.
- 비밀번호 해시는 `PasswordEncoder`를 사용하며 BCrypt를 기본 구현으로 한다.
- 비밀키, 데이터베이스 비밀번호 등 민감 정보는 소스 코드에 직접 작성하지 않는다.

## 4. 개인 작업 환경 구성

각 스터디원은 다음 규칙에 따라 독립된 프로젝트를 구성한다.

```text
members/{이름}/week2/
├── README.md
├── build.gradle(.kts) 또는 pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   └── test/
└── .env.example 또는 환경 변수 설명 문서
```

### 필수 환경 요구사항

- [ ] `members/{이름}/week2`가 하나의 독립된 Spring Boot 프로젝트여야 한다.
- [ ] 프로젝트 빌드 및 테스트가 명령어 한 번으로 실행되어야 한다.
- [ ] 애플리케이션 실행 방법과 필요한 환경 변수를 README에 작성해야 한다.
- [ ] PostgreSQL 연결 정보는 환경 변수 또는 별도 프로필 설정으로 주입해야 한다.
- [ ] 실제 비밀값이 포함된 `.env`, `application-local.yml` 등은 Git에 커밋하지 않아야 한다.
- [ ] 테스트는 운영 PostgreSQL과 분리된 환경에서 수행해야 한다. Testcontainers 또는 별도 테스트 DB 사용을 권장한다.
- [ ] 로컬 실행 후 Swagger UI와 OpenAPI JSON에 접근할 수 있어야 한다.

권장 환경 변수 이름은 다음과 같다.

| 환경 변수 | 설명 |
|---|---|
| `DB_URL` | PostgreSQL JDBC URL |
| `DB_USERNAME` | 데이터베이스 사용자명 |
| `DB_PASSWORD` | 데이터베이스 비밀번호 |
| `JWT_SECRET` | JWT 서명용 비밀키 |
| `JWT_ACCESS_EXPIRATION` | Access Token 만료 시간 |
| `JWT_REFRESH_EXPIRATION` | Refresh Token 만료 시간 |

## 5. 애플리케이션 구조 요구사항

패키지 구성 방식은 자유지만 최소한 다음 책임은 분리해야 한다.

- **Controller:** HTTP 요청 수신, 입력 검증, 응답 상태 코드 결정
- **Service:** 회원가입·로그인 유스케이스와 트랜잭션 경계 처리
- **Repository:** JPA를 통한 데이터 접근
- **Entity:** 영속 상태와 연관관계 표현
- **DTO:** API 요청·응답 표현. 엔터티를 API 응답으로 직접 반환하지 않는다.
- **Security:** JWT 생성·검증, 인증 필터, Security 설정
- **Exception:** 도메인 예외와 공통 오류 응답 변환

의존성 방향과 패키지 구조를 선택한 이유는 개인 README에 설명한다.

## 6. 엔터티 구현 요구사항

Week 1에서 정의한 다음 10개 엔터티를 모두 생성한다.

1. `User`
2. `Movie`
3. `Cinema`
4. `Theater`
5. `Seat`
6. `Screening`
7. `ScreeningSeat`
8. `Reservation`
9. `ReservationSeat`
10. `Payment`

### 공통 구현 기준

- 테이블명, 컬럼명, 타입, NULL 허용 여부, 기본값, 유일성 및 외래키는 Week 1 논리 모델과 DDL에 맞춘다.
- DB의 `snake_case`와 Java의 `camelCase` 매핑이 명확해야 한다.
- 상태값과 역할은 문자열 기반 Enum으로 매핑한다. 순서 변경에 취약한 ordinal 저장은 사용하지 않는다.
- 식별자는 `BIGINT`에 대응하는 타입과 DB 생성 전략을 사용한다.
- 시간 정보는 PostgreSQL `TIMESTAMPTZ`와 호환되는 타입으로 저장하고 UTC 기준으로 처리한다.
- `created_at`, `updated_at` 등 생성·수정 시각은 JPA Auditing 또는 동등한 방식으로 일관되게 관리한다.
- 연관관계의 기본 로딩 전략은 불필요한 즉시 조회를 피하도록 설계한다.
- 양방향 연관관계를 사용한다면 편의 메서드와 JSON 직렬화 순환 방지 방식을 마련한다.
- 엔터티 필드에 API 입력 검증 책임을 과도하게 두지 말고, 요청 DTO 검증과 DB 제약의 역할을 구분한다.
- 애플리케이션 시작 시 임의로 운영 스키마가 변경되지 않도록 `ddl-auto` 정책을 명시한다. `validate` 사용을 권장하며, 스키마 생성은 Week 1 DDL 또는 마이그레이션 도구로 관리한다.

### 반드시 반영할 주요 제약조건

| 대상 | 필수 조건 |
|---|---|
| `users.email` | UNIQUE, NOT NULL |
| `users.nickname` | UNIQUE, NOT NULL |
| `users.role` | `USER`, `ADMIN` |
| `theaters` | `(cinema_id, name)` 복합 UNIQUE |
| `seats` | `(theater_id, seat_row, seat_number)` 복합 UNIQUE |
| `screening_seats` | `(screening_id, seat_id)` 복합 UNIQUE |
| `screening_seats.status` | `AVAILABLE`, `HOLD`, `RESERVED` |
| `reservations.reservation_number` | UNIQUE, NOT NULL |
| `reservations.status` | `PENDING`, `CONFIRMED`, `CANCELLED`, `EXPIRED` |
| `reservation_seats` | 가격 및 좌석 등급 스냅샷 보존 |
| `payments.payment_key` | UNIQUE, NOT NULL |
| `payments.reservation_id` | UNIQUE, 예약과 결제의 1:0..1 관계 |

`reservation_seats.screening_seat_id`에는 단일 UNIQUE 제약을 추가하지 않는다. 취소된 과거 예매 내역을 보존하면서 동일 좌석을 다시 예매할 수 있어야 하기 때문이다.

## 7. 회원가입 API

### `POST /api/v1/auth/signup`

인증 없이 호출할 수 있다.

요청 예시:

```json
{
  "email": "user@example.com",
  "password": "Password1!",
  "password_confirm": "Password1!",
  "name": "홍길동",
  "nickname": "moviegoer",
  "phone": "010-1234-5678"
}
```

### 필수 처리 규칙

- [ ] 이메일, 비밀번호, 비밀번호 확인, 이름, 닉네임, 연락처를 모두 입력받는다.
- [ ] 이메일 형식을 검증한다.
- [ ] 비밀번호와 비밀번호 확인의 일치 여부를 검증한다.
- [ ] 비밀번호는 최소 8자이며 영문, 숫자, 특수문자를 각각 하나 이상 포함한다.
- [ ] 이메일과 닉네임의 중복을 애플리케이션과 DB 제약조건 양쪽에서 방지한다.
- [ ] 비밀번호 원문을 저장하거나 응답·로그에 노출하지 않는다.
- [ ] 비밀번호를 단방향 해시한 후 저장한다.
- [ ] 일반 회원의 기본 역할은 `USER`로 저장한다. 요청을 통해 `ADMIN` 역할을 지정할 수 없어야 한다.
- [ ] 성공 시 `201 Created`를 반환한다.

성공 응답에는 최소한 `id`, `email`, `name`, `nickname`, `role`, `created_at`을 포함하며 `password`는 포함하지 않는다.

### 중복 확인 API

Week 1 API 명세와의 일관성을 위해 다음 API도 구현한다.

- `GET /api/v1/auth/check-email?email={email}`
- `GET /api/v1/auth/check-nickname?nickname={nickname}`

두 API는 인증 없이 호출할 수 있으며, 사용 가능 여부를 Boolean 값으로 명확히 반환한다. 중복 확인 결과와 무관하게 실제 회원가입 시 중복 검증을 다시 수행해야 한다.

## 8. 로그인 및 JWT 인증

### `POST /api/v1/auth/login`

인증 없이 호출할 수 있다.

요청 예시:

```json
{
  "email": "user@example.com",
  "password": "Password1!"
}
```

### 필수 처리 규칙

- [ ] 이메일로 사용자를 조회하고 `PasswordEncoder.matches`로 비밀번호를 검증한다.
- [ ] 이메일 존재 여부와 비밀번호 오류를 외부 응답에서 구분하지 않는다.
- [ ] 인증 성공 시 Access Token과 Refresh Token을 발급한다.
- [ ] 토큰에는 사용자를 식별할 수 있는 subject와 역할 정보가 포함되어야 한다.
- [ ] 토큰 응답에는 `token_type`, `access_token`, `refresh_token`, `expires_in`을 포함한다.
- [ ] 잘못된 자격 증명은 `401 Unauthorized`로 응답한다.
- [ ] 비활성화, 삭제 등 별도 사용자 상태를 추가했다면 로그인 시 해당 상태를 검증한다.

Refresh Token 저장·폐기 및 재발급 API는 이번 주 필수 범위가 아니다. 단, 발급한 Refresh Token을 실제로 사용하도록 구현했다면 저장 위치, 회전 전략, 만료 및 로그아웃 처리 방식을 README에 설명한다.

### 인증 확인 API

`GET /api/v1/users/me`를 구현한다.

- `Authorization: Bearer <Access_Token>` 헤더가 필요하다.
- 유효한 토큰이면 현재 사용자의 `id`, `email`, `name`, `nickname`, `phone`, `role`을 반환한다.
- 토큰이 없거나 유효하지 않거나 만료된 경우 `401 Unauthorized`를 반환한다.
- 다른 사용자의 정보와 비밀번호는 노출하지 않는다.

### Security 접근 정책

| 경로 | 접근 정책 |
|---|---|
| `/api/v1/auth/signup` | 공개 |
| `/api/v1/auth/login` | 공개 |
| `/api/v1/auth/check-email` | 공개 |
| `/api/v1/auth/check-nickname` | 공개 |
| Swagger UI 및 OpenAPI 경로 | 공개 |
| `/api/v1/users/me` | 인증 필요 |
| 그 외 API | 기본적으로 인증 필요 |

서버는 세션을 생성하지 않는 Stateless 방식으로 구성한다. JWT 인증 실패와 인가 실패는 각각 `401 Unauthorized`, `403 Forbidden`으로 구분한다.

## 9. 공통 응답 및 예외 처리

성공 응답 형식은 자유롭게 정할 수 있으나 프로젝트 전체에서 일관되어야 한다. 오류 응답은 최소한 다음 정보를 포함한다.

```json
{
  "success": false,
  "error_code": "DUPLICATE_EMAIL",
  "message": "이미 사용 중인 이메일입니다.",
  "status": 409
}
```

필수 오류 상황은 다음과 같다.

| 오류 코드 예시 | HTTP 상태 | 상황 |
|---|---:|---|
| `VALIDATION_FAILED` | 400 | 요청 형식 또는 필드 검증 실패 |
| `PASSWORD_MISMATCH` | 400 | 비밀번호 확인 불일치 |
| `INVALID_CREDENTIALS` | 401 | 이메일 또는 비밀번호 불일치 |
| `INVALID_TOKEN` | 401 | JWT 누락, 변조 또는 만료 |
| `FORBIDDEN` | 403 | 권한 부족 |
| `DUPLICATE_EMAIL` | 409 | 이메일 중복 |
| `DUPLICATE_NICKNAME` | 409 | 닉네임 중복 |
| `INTERNAL_SERVER_ERROR` | 500 | 예상하지 못한 서버 오류 |

Validation 오류는 어떤 필드가 어떤 이유로 실패했는지 확인할 수 있어야 한다. 예외 처리 방식과 오류 코드 명칭은 변경할 수 있으나 HTTP 상태의 의미는 유지한다.

## 10. Swagger/OpenAPI 문서화

Swagger UI에서 다음 내용을 확인하고 직접 호출할 수 있어야 한다.

- [ ] 회원가입, 이메일·닉네임 중복 확인, 로그인, 내 정보 조회 API
- [ ] 각 API의 목적과 인증 필요 여부
- [ ] 요청 필드의 설명, 필수 여부, 형식 및 예시
- [ ] 성공 응답과 주요 실패 응답의 상태 코드 및 예시
- [ ] Enum 허용값
- [ ] Bearer JWT Security Scheme
- [ ] Swagger UI의 Authorize 기능을 이용한 `/api/v1/users/me` 호출

Swagger 문서가 엔터티 구조를 그대로 노출하지 않도록 요청·응답 DTO를 스키마로 사용한다. 기본 접근 경로가 아닌 경로를 사용했다면 README에 명시한다.

## 11. 테스트 요구사항

최소한 다음 시나리오를 자동화된 테스트로 검증한다.

- [ ] 정상 회원가입
- [ ] 이메일 중복 가입 실패
- [ ] 닉네임 중복 가입 실패
- [ ] 비밀번호 확인 불일치 실패
- [ ] 비밀번호가 해시되어 저장되는지 확인
- [ ] 정상 로그인 및 토큰 발급
- [ ] 잘못된 비밀번호로 로그인 실패
- [ ] 인증 없이 내 정보 조회 실패
- [ ] 유효한 Access Token으로 내 정보 조회 성공
- [ ] 주요 JPA 엔터티 매핑 및 제약조건 확인

테스트 계층과 도구 선택은 자유지만, Service 단위 테스트와 인증 API 통합 테스트를 구분하는 것을 권장한다.

## 12. 제출물

각 스터디원은 `members/{이름}/week2`에 다음 내용을 제출한다.

- 실행 가능한 Spring Boot 프로젝트 전체
- 빌드 및 실행 방법, 환경 변수, Swagger 접속 경로가 포함된 `README.md`
- 엔터티 및 인증 설계 이유
- 테스트 코드와 테스트 실행 결과
- 필요한 DB 마이그레이션 또는 스키마 파일
- `.env.example` 또는 동등한 환경 변수 예시

README에는 최소한 다음 질문에 대한 답을 포함한다.

1. DTO와 Entity를 어떤 기준으로 분리했는가?
2. 연관관계 방향과 지연 로딩 전략을 왜 선택했는가?
3. JWT에 어떤 정보를 담았으며 그 이유는 무엇인가?
4. Refresh Token을 어떻게 취급했는가?
5. 중복 가입 경쟁 조건을 어떻게 처리했는가?
6. 비밀정보와 환경별 설정을 어떻게 분리했는가?

## 13. 완료 조건

다음 조건을 모두 충족하면 과제를 완료한 것으로 본다.

- [ ] 깨끗한 환경에서 프로젝트 빌드와 테스트가 성공한다.
- [ ] PostgreSQL 스키마와 10개 JPA 엔터티의 매핑이 일치한다.
- [ ] 회원가입 후 DB에 BCrypt 등 단방향 해시 비밀번호가 저장된다.
- [ ] 로그인 성공 시 Access Token과 Refresh Token이 발급된다.
- [ ] 발급된 Access Token으로 내 정보 API 호출에 성공한다.
- [ ] 인증 실패, 입력 검증 실패, 중복 가입이 정의된 상태 코드로 응답한다.
- [ ] Swagger UI에서 필수 API 명세를 확인하고 인증 API를 실행할 수 있다.
- [ ] 실제 비밀값이나 개인 로컬 설정이 Git에 포함되지 않는다.

## 14. 이번 주 제외 범위

다음 항목은 엔터티만 생성하며 API와 핵심 비즈니스 로직 구현은 이번 주 필수 범위에서 제외한다.

- 영화·극장·상영 일정 조회 API
- 좌석 선점 및 예매 API
- 결제 승인 및 취소 API
- Redis 분산 락
- Kafka 이벤트 처리
- 외부 PG사 연동
- 관리자용 데이터 등록 API

선택적으로 구현할 수 있으나, 필수 범위의 구조와 테스트를 먼저 완료해야 한다.
