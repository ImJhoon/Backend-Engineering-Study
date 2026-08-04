# 영화 예매 프로젝트 API·MVC 구조 복습 노트

이 문서는 영화 예매 프로젝트를 시작하면서 지금까지 결정하고 변경한 내용을 복습하기 위한 문서입니다.

현재 단계에서는 API를 실제로 구현한 것이 아니라, 다음 개발을 안정적으로 진행할 수 있도록 **API 규칙을 정하고 프로젝트의 기본 패키지 구조를 만든 상태**입니다.

---

## 1. 지금까지 진행한 작업

크게 두 가지 작업을 진행했습니다.

1. `API-Specification.md`에 공통 API 규칙을 추가했습니다.
2. 한 폴더에 모여 있던 엔티티를 도메인별로 분리하고 MVC 기반 패키지 구조를 만들었습니다.

관련 문서와 코드는 다음 위치에서 확인할 수 있습니다.

- API 명세: [`API-Specification.md`](../week1/API-Specification.md)
- 자바 소스 코드: `src/main/java/org/example/cinema`

---

## 2. API란 무엇인가?

API는 클라이언트와 서버가 대화하기 위한 약속입니다.

예를 들어 사용자가 영화 목록 화면에 들어오면 클라이언트는 서버에 다음과 같은 요청을 보낼 수 있습니다.

```http
GET /api/v1/movies?page=1&size=20
```

서버는 요청을 처리한 뒤 JSON 형식으로 결과를 반환합니다.

```json
{
  "success": true,
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "size": 20,
      "total_elements": 0,
      "total_pages": 0
    }
  }
}
```

API 명세에는 다음 내용이 포함되어야 합니다.

- 어떤 주소로 요청하는가?
- `GET`, `POST`, `DELETE` 중 어떤 HTTP 메서드를 사용하는가?
- 어떤 데이터를 전달해야 하는가?
- 로그인이 필요한가?
- 성공하면 어떤 데이터를 반환하는가?
- 실패하면 어떤 오류를 반환하는가?

API 명세를 먼저 작성하면 프론트엔드와 백엔드가 동일한 규칙을 보고 개발할 수 있습니다.

---

## 3. 이번에 보완한 API 공통 규칙

### 3.1 성공 응답 JSON 구조

모든 성공 응답은 다음과 같이 `success`와 `data`를 갖도록 정했습니다.

```json
{
  "success": true,
  "data": {
    "id": 1
  }
}
```

- `success`: 요청 성공 여부입니다.
- `data`: 실제 응답 데이터입니다.

목록 API에는 목록뿐만 아니라 페이지 정보도 포함합니다.

```json
{
  "success": true,
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "size": 20,
      "total_elements": 0,
      "total_pages": 0
    }
  }
}
```

페이지 번호는 1부터 시작하도록 정했습니다.

주요 성공 상태 코드는 다음과 같습니다.

| 상태 코드 | 의미 | 사용 예시 |
|---|---|---|
| `200 OK` | 요청을 정상 처리함 | 조회, 로그아웃, 예매 취소 |
| `201 Created` | 새로운 데이터가 생성됨 | 회원가입, 예매 생성 |
| `202 Accepted` | 요청은 받았지만 처리가 아직 확정되지 않음 | 결제 결과 확인 중 |

### 3.2 실패 응답 JSON 구조

실패 응답은 다음과 같은 공통 구조를 사용합니다.

```json
{
  "success": false,
  "error_code": "SEAT_ALREADY_TAKEN",
  "message": "이미 다른 사용자가 선점한 좌석입니다.",
  "status": 409
}
```

- `error_code`: 프로그램이 오류 종류를 구분할 때 사용합니다.
- `message`: 사용자 또는 개발자가 읽을 수 있는 설명입니다.
- `status`: HTTP 상태 코드입니다.

오류 응답을 통일하면 클라이언트가 API마다 다른 방식으로 오류를 처리하지 않아도 됩니다.

### 3.3 날짜와 시간대

시간은 환경에 따라 다르게 해석될 수 있습니다. 예를 들어 한국의 오후 3시는 UTC 기준으로 오전 6시입니다.

이 프로젝트에서는 다음 규칙을 사용합니다.

- 서버와 데이터베이스에는 시간을 UTC 기준으로 저장합니다.
- API 시간은 RFC 3339 형식으로 전달합니다.
- 한국 날짜 기준 검색에는 `Asia/Seoul` 시간대를 사용합니다.

UTC 시간 예시는 다음과 같습니다.

```text
2024-03-01T05:30:00Z
```

마지막의 `Z`는 UTC 시간이라는 뜻입니다.

상영 일정 조회의 다음 요청은 한국 시간 기준 2024년 3월 1일의 상영 일정을 의미합니다.

```http
GET /api/v1/screenings?date=2024-03-01
```

서버는 이를 `Asia/Seoul` 기준 3월 1일 00:00 이상, 3월 2일 00:00 미만으로 해석합니다.

### 3.4 API별 인증 여부

인증은 사용자가 누구인지 확인하는 과정입니다. 이 프로젝트는 서버 세션과 세션 쿠키 기반 인증을 사용합니다. 로그인에 성공하면 서버가 인증 정보를 세션에 저장하고 브라우저에 세션 식별 쿠키를 전달합니다.

```http
Cookie: JSESSIONID=<session-id>
```

브라우저가 세션 쿠키를 자동으로 전송하므로 상태 변경 요청에는 CSRF 보호를 적용합니다. 클라이언트는 `GET /api/v1/auth/csrf`로 토큰을 발급받고 `POST`, `PUT`, `PATCH`, `DELETE` 요청에 `X-XSRF-TOKEN` 헤더를 포함합니다.

인증 없이 접근 가능한 주요 API는 다음과 같습니다.

- 회원가입
- 이메일 및 닉네임 중복 확인
- 로그인
- 영화 목록 및 상세 조회
- 영화관 조회
- 상영 일정 및 좌석 상태 조회

인증이 필요한 주요 API는 다음과 같습니다.

- 로그아웃
- 내 정보 조회
- 예매 생성
- 내 예매 조회
- 예매 취소
- 결제 승인

다른 사용자의 예매를 조회하거나 취소하지 못하도록 예매 상세 조회, 취소, 결제 시에는 **현재 로그인한 사용자가 해당 예매의 소유자인지**도 확인해야 합니다.

인증과 권한은 서로 다른 개념입니다.

- 인증(Authentication): 이 사용자가 누구인가?
- 권한 확인(Authorization): 이 사용자가 이 작업을 해도 되는가?

### 3.5 결제 실패와 재시도

결제 요청은 네트워크 문제로 응답이 늦거나 끊길 수 있습니다. 이때 단순히 새로운 결제를 다시 요청하면 같은 결제가 두 번 승인될 수 있습니다.

이를 방지하기 위해 `Idempotency-Key`를 사용합니다.

```http
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```

멱등성이란 **같은 요청을 여러 번 보내도 최종 결과가 한 번 보낸 것과 같아야 한다**는 뜻입니다.

이번에 정한 결제 정책은 다음과 같습니다.

1. PG사에 요청하기 전에 예매 소유자, 예매 상태, 만료 시간, 금액을 검증합니다.
2. 같은 결제를 재전송할 때는 같은 멱등키와 같은 요청 내용을 사용합니다.
3. 같은 멱등키로 다른 내용을 보내면 `409 Conflict`를 반환합니다.
4. 결제 승인 결과를 알 수 없다면 무조건 새 승인 요청을 보내지 않습니다.
5. 결제 상태를 `PENDING`으로 보존하고 PG사 조회 또는 비동기 대사 작업으로 결과를 확인합니다.
6. 카드 거절이나 금액 불일치처럼 확정된 실패는 자동 재시도하지 않습니다.

PG는 Payment Gateway의 약자로, 카드사 등 외부 결제 시스템과 애플리케이션 사이에서 결제를 처리하는 서비스입니다.

---

## 4. 엔티티란 무엇인가?

엔티티(Entity)는 데이터베이스 테이블과 연결되는 자바 객체입니다.

예를 들어 `Movie` 엔티티는 `movies` 테이블과 연결됩니다.

```java
@Entity
@Table(name = "movies")
public class Movie {
    @Id
    private Long id;

    private String title;
}
```

주요 JPA 어노테이션의 의미는 다음과 같습니다.

| 어노테이션 | 의미 |
|---|---|
| `@Entity` | 이 클래스가 JPA 엔티티임을 나타냄 |
| `@Table` | 연결할 데이터베이스 테이블을 지정함 |
| `@Id` | 기본 키(Primary Key)를 나타냄 |
| `@Column` | 연결할 테이블 컬럼 정보를 지정함 |
| `@ManyToOne` | 여러 데이터가 하나의 데이터를 참조하는 관계 |
| `@OneToOne` | 하나의 데이터가 하나의 데이터와 연결되는 관계 |
| `@JoinColumn` | 외래 키 컬럼을 지정함 |

기존에는 모든 엔티티가 다음 패키지에 모여 있었습니다.

```text
org.example.cinema.entity
├─ User.java
├─ Movie.java
├─ Cinema.java
├─ Screening.java
├─ Reservation.java
└─ ...
```

엔티티 수가 적을 때는 단순하지만 기능이 늘어나면 어떤 코드가 어떤 기능에 속하는지 파악하기 어려워집니다.

---

## 5. 도메인이란 무엇인가?

도메인은 프로그램이 해결하려는 업무 영역을 의미합니다.

영화 예매 서비스에서는 다음과 같이 기능을 나눌 수 있습니다.

| 도메인 | 담당 내용 | 포함된 엔티티 |
|---|---|---|
| `user` | 사용자 정보 | `User` |
| `movie` | 영화 정보 | `Movie` |
| `cinema` | 영화관, 상영관, 물리 좌석 | `Cinema`, `Theater`, `Seat` |
| `screening` | 영화 상영 일정과 회차별 좌석 상태 | `Screening`, `ScreeningSeat` |
| `reservation` | 예매와 예매 좌석 스냅샷 | `Reservation`, `ReservationSeat` |
| `payment` | 결제 정보 | `Payment` |
| `auth` | 로그인, 로그아웃, 세션 및 CSRF 처리 | 별도 엔티티 없음 |

`Seat`와 `ScreeningSeat`의 차이를 이해하는 것이 중요합니다.

- `Seat`: A열 1번 좌석처럼 상영관에 실제로 존재하는 물리 좌석입니다.
- `ScreeningSeat`: 특정 상영 회차에서 해당 좌석이 예매 가능한지 나타냅니다.

같은 `Seat`라도 상영 회차마다 예약 상태가 달라질 수 있으므로 `ScreeningSeat`가 별도로 필요합니다.

---

## 6. MVC 패턴이란 무엇인가?

MVC는 코드를 역할별로 나누는 설계 방식입니다.

- Model: 데이터와 비즈니스 규칙을 담당합니다.
- View: 사용자에게 보여줄 결과를 담당합니다.
- Controller: 요청을 받아 적절한 로직으로 연결합니다.

Spring 기반 REST API에서는 MVC를 다음처럼 확장하여 사용하는 경우가 많습니다.

```text
HTTP 요청
    ↓
Controller
    ↓
Service
    ↓
Repository
    ↓
Database
```

처리 결과는 반대 방향으로 돌아옵니다.

```text
Database → Repository → Service → DTO → Controller → JSON 응답
```

각 계층의 역할은 다음과 같습니다.

### Controller

HTTP 요청과 응답을 담당합니다.

- URL과 HTTP 메서드를 연결합니다.
- 요청값을 DTO로 받습니다.
- 입력값의 기본 형식을 검증합니다.
- Service를 호출합니다.
- 처리 결과를 HTTP 응답으로 반환합니다.

Controller에 복잡한 비즈니스 로직을 직접 작성하지 않는 것이 좋습니다.

### Service

업무 규칙과 처리 순서를 담당합니다.

예매 생성 Service는 다음과 같은 일을 처리할 수 있습니다.

1. 상영 일정이 존재하는지 확인합니다.
2. 선택한 좌석이 예매 가능한지 확인합니다.
3. 좌석을 선점합니다.
4. 예매 만료 시간을 계산합니다.
5. 예매 정보를 저장합니다.

### Repository

데이터베이스 접근을 담당합니다.

- 엔티티 저장
- ID로 엔티티 조회
- 조건에 맞는 목록 조회
- 데이터 삭제 또는 상태 변경

Spring Data JPA를 사용하면 보통 `JpaRepository`를 상속해 작성합니다.

```java
public interface MovieRepository extends JpaRepository<Movie, Long> {
}
```

### Entity

데이터베이스 테이블과 연결되는 객체입니다. API 요청과 응답에 엔티티를 직접 사용하는 것은 피하는 것이 좋습니다.

### DTO

DTO는 Data Transfer Object의 약자로, 계층 또는 네트워크 사이에서 데이터를 전달하기 위한 객체입니다.

```java
public record CreateReservationRequest(
    Long screeningId,
    List<Long> screeningSeatIds
) {
}
```

REST API에서는 DTO가 JSON 응답 형태를 결정하므로 View 역할도 일부 담당합니다.

엔티티와 DTO를 분리하면 다음 장점이 있습니다.

- 데이터베이스 구조가 API에 그대로 노출되지 않습니다.
- 비밀번호 같은 민감한 필드 노출을 방지할 수 있습니다.
- API 형식이 바뀌어도 엔티티 변경을 줄일 수 있습니다.
- 요청별 검증 규칙을 분리할 수 있습니다.

---

## 7. 프로젝트의 목표 패키지 구조

이 프로젝트는 계층을 최상위에 모두 모으는 방식이 아니라, **도메인을 먼저 나누고 그 안에서 계층을 나누는 방식**으로 구현할 예정입니다.

```text
org.example.cinema
├─ auth
│  ├─ controller
│  ├─ dto
│  └─ service
├─ user
│  ├─ controller
│  ├─ dto
│  ├─ entity
│  ├─ repository
│  └─ service
├─ movie
│  ├─ controller
│  ├─ dto
│  ├─ entity
│  ├─ repository
│  └─ service
├─ cinema
│  ├─ controller
│  ├─ dto
│  ├─ entity
│  ├─ repository
│  └─ service
├─ screening
│  ├─ controller
│  ├─ dto
│  ├─ entity
│  ├─ repository
│  └─ service
├─ reservation
│  ├─ controller
│  ├─ dto
│  ├─ entity
│  ├─ repository
│  └─ service
└─ payment
   ├─ controller
   ├─ dto
   ├─ entity
   ├─ repository
   └─ service
```

이 방식을 도메인 중심 패키지 구조 또는 Package by Feature라고 부릅니다.

다음처럼 모든 Controller를 한곳에 모으는 Package by Layer 방식도 있습니다.

```text
controller
service
repository
entity
dto
```

현재 프로젝트는 영화, 상영, 예매, 결제처럼 업무 경계가 명확하므로 도메인 중심 구조가 더 적합합니다. 특정 기능을 수정할 때 관련 코드를 한 패키지 안에서 쉽게 찾을 수 있기 때문입니다.

---

## 8. 엔티티 이동 시 수정한 내용

자바 클래스는 파일 위치와 `package` 선언이 일치해야 합니다.

예를 들어 기존 `Reservation`의 패키지는 다음과 같았습니다.

```java
package org.example.cinema.entity;
```

현재는 다음과 같이 변경되었습니다.

```java
package org.example.cinema.reservation.entity;
```

서로 다른 패키지의 엔티티를 사용하는 경우에는 `import`도 필요합니다.

```java
import org.example.cinema.screening.entity.Screening;
import org.example.cinema.user.entity.User;
```

예를 들어 `Reservation`은 사용자와 상영 일정을 참조하므로 위 두 클래스를 import합니다.

이동하면서 수정한 주요 관계는 다음과 같습니다.

```text
Theater ──→ Cinema
Seat ──→ Theater
Screening ──→ Movie, Theater
ScreeningSeat ──→ Screening, Seat
Reservation ──→ User, Screening
ReservationSeat ──→ Reservation, ScreeningSeat
Payment ──→ Reservation
```

화살표는 왼쪽 엔티티가 오른쪽 엔티티를 참조한다는 뜻입니다.

`CinemaApplication`이 `org.example.cinema` 최상위 패키지에 있기 때문에 Spring Boot는 그 아래의 도메인별 엔티티를 자동으로 탐색할 수 있습니다. 따라서 별도의 `@EntityScan` 설정은 현재 필요하지 않습니다.

---

## 9. 아직 구현하지 않은 빈 패키지는 어떻게 관리하는가?

Git은 빈 디렉터리를 저장하지 않습니다. `controller`, `service`, `repository`, `dto` 폴더만 만들고 파일을 넣지 않으면 커밋했을 때 폴더가 사라집니다.

초기에는 빈 패키지를 Git에 보존하기 위해 `package-info.java`를 사용했지만, 실제 구현이 없는 디렉터리를 미리 유지하지 않기로 결정하여 모두 제거했습니다.

따라서 현재는 엔티티처럼 실제 클래스가 있는 패키지만 Git에 저장됩니다. `controller`, `service`, `repository`, `dto` 패키지는 해당 기능을 구현할 때 필요한 클래스를 추가하면서 자연스럽게 생성합니다.

예를 들어 영화 목록 API를 구현할 때 `MovieController`, `MovieService`, `MovieRepository`, 응답 DTO를 추가하면 관련 패키지도 함께 Git에 저장됩니다.

---

## 10. 엔드포인트별 폴더를 만들지 않은 이유

다음처럼 API 주소 하나마다 폴더를 만들 수도 있습니다.

```text
get-movies
get-movie-detail
create-reservation
cancel-reservation
```

하지만 이 방식은 엔드포인트가 늘어날수록 폴더가 지나치게 많아지고, 같은 업무에 속한 코드가 여러 곳에 흩어집니다.

따라서 현재는 엔드포인트가 아니라 도메인을 기준으로 묶었습니다.

```text
reservation
├─ controller
├─ service
├─ repository
├─ entity
└─ dto
```

`POST /reservations`, `GET /reservations/{id}`, `DELETE /reservations/{id}`는 모두 예매 도메인에 속하므로 같은 패키지에서 관리합니다.

URL과 자바 패키지가 반드시 동일할 필요도 없습니다. 예를 들어 다음 API는 URL이 `users`로 시작하지만 예매 목록을 조회하는 기능이므로 예약 도메인의 Controller와 Service에서 담당할 수 있습니다.

```http
GET /api/v1/users/me/reservations
```

---

## 11. 현재 구현된 것과 아직 구현되지 않은 것

현재 완료된 내용은 다음과 같습니다.

- API 엔드포인트 초안 작성
- 성공 및 실패 응답 규칙 정의
- 날짜 및 시간대 규칙 정의
- API별 인증 여부 정의
- 결제 실패 및 재시도 정책 정의
- JPA 엔티티 작성
- 엔티티의 도메인별 패키지 이동
- 도메인별 엔티티 패키지 생성
- 변경 후 컴파일과 테스트 확인

아직 구현되지 않은 내용은 다음과 같습니다.

- 실제 Controller 클래스와 URL 매핑
- 요청 및 응답 DTO
- Service 비즈니스 로직
- Spring Data JPA Repository
- 세션 로그인·로그아웃 및 인증 정보 저장
- 공통 성공·오류 응답 클래스
- 전역 예외 처리
- 좌석 동시성 제어
- PG사 실제 연동
- 결제 비동기 대사 작업

즉, 현재는 엔티티와 공통 Auditing 구조만 준비된 상태이며 실제 API가 동작하는 상태는 아닙니다.

---

## 12. 구조 변경 검증

패키지 이동 후 다음 내용을 확인했습니다.

1. 기존 `org.example.cinema.entity` 참조가 남아 있지 않은지 검색했습니다.
2. 엔티티 사이의 import가 새 패키지를 가리키도록 수정했습니다.
3. Gradle 테스트를 실행했습니다.

실행한 명령은 다음과 같습니다.

```powershell
.\gradlew.bat test
```

결과는 다음과 같습니다.

```text
BUILD SUCCESSFUL
```

이 결과는 최소한 다음 사항이 정상이라는 의미입니다.

- 자바 문법과 import가 올바릅니다.
- 변경된 패키지의 클래스가 컴파일됩니다.
- Spring Boot가 애플리케이션 컨텍스트를 생성할 수 있습니다.
- JPA가 이동한 엔티티를 탐색할 수 있습니다.

다만 테스트 성공이 모든 비즈니스 기능이 완성되었다는 뜻은 아닙니다. 아직 실제 API 기능은 구현 전이므로 이후 각 기능에 대한 테스트를 추가해야 합니다.

---

## 13. 앞으로 구현할 때 권장하는 순서

모든 엔드포인트의 빈 클래스를 한꺼번에 만드는 것보다 기능 하나를 끝까지 구현해 공통 패턴을 정하는 것이 좋습니다.

처음에는 비교적 단순한 영화 목록 조회 API를 다음 순서로 구현할 수 있습니다.

```text
MovieRepository
    ↓
MovieService
    ↓
MovieResponse DTO
    ↓
MovieController
    ↓
Controller 테스트
```

그다음 핵심 기능인 예매 생성을 구현하면서 트랜잭션과 동시성 제어를 학습할 수 있습니다.

권장 순서는 다음과 같습니다.

1. 공통 성공·오류 응답 클래스
2. 영화 목록 및 상세 조회
3. 영화관과 상영 일정 조회
4. 회원가입과 로그인
5. 좌석 상태 조회
6. 예매 생성과 좌석 선점
7. 예매 조회와 취소
8. 결제 승인
9. 동시성 및 실패 복구 테스트

---

## 14. 복습할 핵심 문장

- API 명세는 클라이언트와 서버가 데이터를 주고받는 약속이다.
- 엔티티는 데이터베이스 테이블과 연결되는 객체다.
- DTO는 API 요청과 응답에 사용할 데이터를 담는 객체다.
- Controller는 HTTP 요청을 받고 Service를 호출한다.
- Service는 비즈니스 규칙과 작업 순서를 담당한다.
- Repository는 데이터베이스 접근을 담당한다.
- 도메인은 사용자, 영화, 예매처럼 업무 기능을 나눈 경계다.
- 현재 프로젝트는 도메인을 먼저 나누고 그 안에 MVC 계층을 두었다.
- 엔티티를 이동하면 `package`와 `import`도 함께 수정해야 한다.
- 같은 결제 요청의 중복 처리는 멱등키를 이용해 방지한다.
- 인증은 사용자가 누구인지 확인하는 것이고, 권한 확인은 그 사용자가 해당 작업을 수행해도 되는지 판단하는 것이다.
- 테스트가 성공해도 아직 작성하지 않은 기능까지 완성된 것은 아니다.

---

## 15. 용어 요약

| 용어 | 쉬운 설명 |
|---|---|
| API | 클라이언트와 서버가 대화하는 규칙 |
| Endpoint | 하나의 API 주소와 HTTP 메서드 조합 |
| JSON | API에서 데이터를 표현하는 형식 |
| MVC | 코드를 데이터, 화면 결과, 요청 처리 역할로 나누는 방식 |
| Domain | 프로그램이 처리하는 업무 영역 |
| Entity | 데이터베이스 테이블과 연결되는 자바 객체 |
| DTO | 요청과 응답 데이터를 전달하는 객체 |
| Repository | 데이터베이스에 접근하는 계층 |
| Service | 비즈니스 로직을 처리하는 계층 |
| Controller | HTTP 요청을 받고 응답하는 계층 |
| JPA | 자바 객체와 관계형 데이터베이스를 연결하는 기술 |
| Session | 로그인한 사용자의 인증 정보를 서버에 보관하는 저장 영역 |
| Session Cookie | 브라우저가 서버 세션을 식별할 수 있도록 전달하는 쿠키 |
| CSRF Token | 쿠키 기반 인증에서 다른 사이트가 요청을 위조하지 못하도록 검증하는 값 |
| UTC | 전 세계 시간 계산의 기준이 되는 시간대 |
| PG | 외부 결제를 처리하는 결제 대행 서비스 |
| Idempotency | 같은 요청을 반복해도 결과가 중복되지 않는 성질 |
| Transaction | 여러 데이터 변경을 하나의 작업 단위로 처리하는 것 |
