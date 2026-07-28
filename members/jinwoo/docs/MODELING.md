# [Week 1] 도메인 모델링

## 1. 구현 내용

영화 예매 시스템의 회원, 영화, 상영관, 좌석, 상영 일정, 예매 도메인을 모델링했습니다.

### 엔티티 구성

| 엔티티 | 주요 속성 | 역할 |
| --- | --- | --- |
| `MEMBER` | 이메일, 비밀번호, 닉네임, 권한 | 회원 정보 관리 |
| `MOVIE` | 제목, 상영 시간 | 영화 정보 관리 |
| `THEATER` | 이름 | 영화관 정보 관리 |
| `AUDITORIUM` | 영화관, 이름, 전체 좌석 수 | 영화관 내부 상영관 관리 |
| `SEAT` | 상영관, 행, 번호 | 상영관의 물리 좌석 관리 |
| `SCREENING` | 영화, 상영관, 시작·종료 시간, 상태 | 영화별 상영 일정 관리 |
| `SCREENING_SEAT` | 상영 일정, 좌석, 상태, 가격, 선점 만료 시간 | 상영 일정별 좌석 상태 관리 |
| `RESERVATION` | 예매번호, 회원, 상영 일정, 상태, 총 금액 | 회원의 예매 정보 관리 |
| `RESERVATION_SEAT` | 예매, 상영 좌석, 가격 | 예매에 포함된 좌석 관리 |

### 엔티티 관계

- 한 영화관은 여러 상영관을 가진다.
- 한 상영관은 여러 좌석과 상영 일정을 가진다.
- 한 영화는 여러 상영 일정을 가진다.
- 하나의 상영 일정에는 좌석별 상태를 관리하는 상영 좌석이 생성된다.
- 한 회원은 여러 예매를 할 수 있다.
- 한 예매는 하나의 상영 일정과 하나 이상의 예매 좌석으로 구성된다.

### 논리적 모델링

#### 1. MEMBER (회원)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`MEMBER.id`) | 회원 고유 식별자 |
| email | VARCHAR | UNIQUE, NOT NULL | 로그인 이메일 |
| password | VARCHAR | NOT NULL | 암호화된 비밀번호 |
| nickname | VARCHAR | UNIQUE, NOT NULL | 회원 닉네임 |
| role | VARCHAR | NOT NULL | 회원 권한 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 2. MOVIE (영화)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`MOVIE.id`) | 영화 고유 식별자 |
| title | VARCHAR | NOT NULL | 영화 제목 |
| running_time_minutes | INTEGER | NOT NULL, CHECK (`> 0`) | 상영 시간(분) |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 3. THEATER (영화관)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`THEATER.id`) | 영화관 고유 식별자 |
| name | VARCHAR | NOT NULL | 영화관 이름 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 4. AUDITORIUM (상영관)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`AUDITORIUM.id`) | 상영관 고유 식별자 |
| theater_id | BIGINT | FK → `THEATER.id`, NOT NULL, UNIQUE (`theater_id`, `name`) | 소속 영화관 식별자 |
| name | VARCHAR | NOT NULL, UNIQUE (`theater_id`, `name`) | 상영관 이름 |
| total_seats | INTEGER | NOT NULL, CHECK (`>= 0`) | 전체 좌석 수 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 5. SEAT (좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`SEAT.id`) | 좌석 고유 식별자 |
| auditorium_id | BIGINT | FK → `AUDITORIUM.id`, NOT NULL, UNIQUE (`auditorium_id`, `row_name`, `seat_number`) | 소속 상영관 식별자 |
| row_name | VARCHAR | NOT NULL, UNIQUE (`auditorium_id`, `row_name`, `seat_number`) | 좌석 행 이름 |
| seat_number | INTEGER | NOT NULL, CHECK (`> 0`), UNIQUE (`auditorium_id`, `row_name`, `seat_number`) | 좌석 번호 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 6. SCREENING (상영 일정)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`SCREENING.id`) | 상영 일정 고유 식별자 |
| movie_id | BIGINT | FK → `MOVIE.id`, NOT NULL | 상영 영화 식별자 |
| auditorium_id | BIGINT | FK → `AUDITORIUM.id`, NOT NULL | 상영관 식별자 |
| start_time | TIMESTAMP | NOT NULL, CHECK (`start_time < end_time`) | 상영 시작 시각 |
| end_time | TIMESTAMP | NOT NULL, CHECK (`start_time < end_time`) | 상영 종료 시각 |
| status | VARCHAR | NOT NULL | 상영 상태 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 7. SCREENING_SEAT (상영 좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`SCREENING_SEAT.id`) | 상영 좌석 고유 식별자 |
| screening_id | BIGINT | FK → `SCREENING.id`, NOT NULL, UNIQUE (`screening_id`, `seat_id`) | 상영 일정 식별자 |
| seat_id | BIGINT | FK → `SEAT.id`, NOT NULL, UNIQUE (`screening_id`, `seat_id`) | 물리 좌석 식별자 |
| status | VARCHAR | NOT NULL | 좌석 예매 상태 |
| price | BIGINT | NOT NULL, CHECK (`>= 0`) | 좌석 가격 |
| hold_expires_at | TIMESTAMP | - | 좌석 선점 만료 시각 |
| version | BIGINT | NOT NULL, CHECK (`>= 0`) | 동시성 제어 버전 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 8. RESERVATION (예매)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`RESERVATION.id`) | 예매 고유 식별자 |
| reservation_number | VARCHAR | UNIQUE, NOT NULL | 외부 노출용 예매번호 |
| member_id | BIGINT | FK → `MEMBER.id`, NOT NULL | 예매 회원 식별자 |
| screening_id | BIGINT | FK → `SCREENING.id`, NOT NULL | 상영 일정 식별자 |
| status | VARCHAR | NOT NULL | 예매 상태 |
| total_amount | INTEGER | NOT NULL, CHECK (`>= 0`) | 총 예매 금액 |
| expires_at | TIMESTAMP | - | 예매 만료 시각 |
| reserved_at | TIMESTAMP | NOT NULL | 예매 확정 시각 |
| canceled_at | TIMESTAMP | - | 예매 취소 시각 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |
| updated_at | TIMESTAMP | - | 수정 일시 |

#### 9. RESERVATION_SEAT (예매 좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
| --- | --- | --- | --- |
| id | BIGINT | PK (`RESERVATION_SEAT.id`) | 예매 좌석 고유 식별자 |
| reservation_id | BIGINT | FK → `RESERVATION.id`, NOT NULL, UNIQUE (`reservation_id`, `screening_seat_id`) | 예매 식별자 |
| screening_seat_id | BIGINT | FK → `SCREENING_SEAT.id`, NOT NULL, UNIQUE (`reservation_id`, `screening_seat_id`) | 상영 좌석 식별자 |
| price | INTEGER | NOT NULL, CHECK (`>= 0`) | 예매 당시 좌석 가격 |
| created_at | TIMESTAMP | NOT NULL | 생성 일시 |

### 애플리케이션 검증 규칙

- 탈퇴 또는 정지 회원은 예매할 수 없으며 회원은 본인의 예매만 관리할 수 있다.
- 상영 종료 영화에는 새로운 상영 일정을 생성할 수 없다.
- 동일 상영관에 시간이 겹치는 상영 일정을 생성할 수 없다.
- 상영 종료 시각은 시작 시각과 영화 상영 시간을 기준으로 계산한다.
- 시작했거나 종료된 상영 일정은 예매할 수 없다.
- 좌석은 선점 가능 상태에서만 선점하며, 선점 만료 시 다시 선택 가능한 상태로 변경한다.
- 예매에는 같은 상영 일정에 속한 좌석이 1개 이상 포함되어야 한다.
- 예매 총 금액은 예매 좌석 가격의 합과 같아야 한다.
- 확정된 예매에는 좌석을 추가할 수 없으며, 상영 시작 이후 또는 이미 취소된 예매는 취소할 수 없다.
