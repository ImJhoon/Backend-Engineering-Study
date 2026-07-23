# [Week 1] 도메인 모델링 - 논리적 모델링

## 1. 구현 내용

## 1. Users (사용자)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 사용자 고유 식별자 |
| email | VARCHAR | UNIQUE, NOT NULL | 로그인/식별용 이메일 |
| password | VARCHAR | NOT NULL | 암호화된 비밀번호 |
| name | VARCHAR | NOT NULL | 사용자 실명 (결제/CS용) |
| nickname | VARCHAR | UNIQUE, NOT NULL | 화면 표시용 닉네임 |
| phone | VARCHAR | NOT NULL | 연락처 |
| role | VARCHAR(ENUM) | NOT NULL, DEFAULT 'USER', CHECK (role IN ('USER', 'ADMIN')) | USER / ADMIN 등 |
| created_at | TIMESTAMPTZ | NOT NULL | 가입일시 (UTC 기준) |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 수정일시 |

## 2. Movies (영화)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 영화 고유 식별자 |
| title | VARCHAR | NOT NULL | 영화 제목 |
| running_time | INT | NOT NULL, CHECK (running_time > 0) | 러닝타임(분) |
| rating | VARCHAR(ENUM) | NOT NULL | 관람등급 (전체/12세/15세/청불) |
| release_date | DATE | NOT NULL | 개봉일 |
| genre | VARCHAR | NULL | 장르 |
| director | VARCHAR | NULL | 감독 |
| cast | VARCHAR | NULL | 출연진 |
| plot | TEXT | NULL | 줄거리 |
| poster_url | VARCHAR | NULL | 포스터 이미지 경로 |

## 3. Cinemas (지점)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 지점 고유 식별자 |
| name | VARCHAR | NOT NULL | 지점명 (예: 강남점) |
| address | VARCHAR | NOT NULL | 주소 |
| phone | VARCHAR | NULL | 지점 대표 연락처 |

## 4. Theaters (상영관)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 상영관 고유 식별자 |
| cinema_id | BIGINT | FK(Cinemas.id), NOT NULL | 소속 지점 |
| name | VARCHAR | NOT NULL | 관 이름 (예: 1관) |
| theater_type | VARCHAR(ENUM) | NOT NULL, DEFAULT 'STANDARD' | 상영관 종류 (STANDARD / IMAX / 4DX / DOLBY 등) |
| total_seat_count | INT | NOT NULL, CHECK (total_seat_count > 0) | 전체 좌석 수 |

## 5. Seats (좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 좌석 고유 식별자 |
| theater_id | BIGINT | FK(Theaters.id), NOT NULL | 소속 상영관 |
| seat_row | VARCHAR | NOT NULL | 좌석 열 (예: A) |
| seat_number | INT | NOT NULL | 좌석 번호 (예: 1) |
| seat_grade | VARCHAR(ENUM) | NOT NULL | 일반/프리미엄/커플석 등 |


## 6. Screenings (상영 일정)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 상영 일정 고유 식별자 |
| movie_id | BIGINT | FK(Movies.id), NOT NULL | 상영 영화 |
| theater_id | BIGINT | FK(Theaters.id), NOT NULL | 상영관 |
| start_time | TIMESTAMPTZ | NOT NULL | 상영 시작 시각 (UTC 기준) |
| end_time | TIMESTAMPTZ | NOT NULL, CHECK (end_time > start_time) | 상영 종료 시각 (UTC 기준) |
| base_price | INT | NOT NULL, CHECK (base_price >= 0) | 기본 요금 (시간대/조조 등 반영) |


## 7. Screening_Seats (상영 좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 상영 좌석 고유 식별자 |
| screening_id | BIGINT | FK(Screenings.id), NOT NULL | 상영 일정 |
| seat_id | BIGINT | FK(Seats.id), NOT NULL | 물리 좌석 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'AVAILABLE', CHECK (status IN ('AVAILABLE', 'HOLD', 'RESERVED')) | AVAILABLE / HOLD / RESERVED |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 수정일시 |

## 8. Reservations (예약)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 예약 고유 식별자 |
| reservation_number | VARCHAR | UNIQUE, NOT NULL | 고객 노출용 고유 예매번호 (예: A1B2C3D4) |
| user_id | BIGINT | FK(Users.id), NOT NULL | 예약자 |
| screening_id | BIGINT | FK(Screenings.id), NOT NULL | 예약 대상 상영 일정 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'PENDING', CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED')) | PENDING / CONFIRMED / CANCELLED / EXPIRED |
| reserved_at | TIMESTAMPTZ | NOT NULL | 예약(선점) 시각 (UTC 기준) |
| expires_at | TIMESTAMPTZ | NULL | 결제 대기 만료 시각 (UTC 기준) |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 수정일시 |

## 9. Reservation_Seats (예약 좌석 / 예매 상세)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 예약 좌석 고유 식별자 |
| reservation_id | BIGINT | FK(Reservations.id), NOT NULL | 소속 예약 |
| screening_seat_id | BIGINT | FK(Screening_Seats.id), NOT NULL | 지정된 상영 좌석 |
| seat_grade_snapshot | VARCHAR | NOT NULL | 예매 당시 좌석 등급 스냅샷 |
| price_snapshot | INT | NOT NULL, CHECK (price_snapshot >= 0) | 예매 당시 가격 스냅샷 |
| cancel_status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'NONE', CHECK (cancel_status IN ('NONE', 'CANCELLED')) | 좌석 단위 취소 상태 |

## 10. Payments (결제)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 결제 고유 식별자 |
| payment_key | VARCHAR | UNIQUE, NOT NULL | 외부 PG사 통신용 고유 결제 키 (주문번호) |
| reservation_id | BIGINT | FK(Reservations.id), NOT NULL, UNIQUE | 대상 예약 (1:0..1 관계 반영) |
| amount | INT | NOT NULL, CHECK (amount >= 0) | 결제 금액 |
| method | VARCHAR(ENUM) | NOT NULL | 카드/간편결제 등 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'PENDING', CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED')) | PENDING / COMPLETED / FAILED / CANCELLED |
| paid_at | TIMESTAMPTZ | NULL | 결제 완료 시각 (UTC 기준) |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 수정일시 |

## 11. Indexes (인덱스)

| 인덱스명 | 대상 테이블 | 컬럼 | 목적 |
|---|---|---|---|
| idx_screenings_movie | Screenings | movie_id | 영화별 상영 일정 조회 |
| idx_screenings_theater_start | Screenings | theater_id, start_time | 상영관별 시간순 상영 일정 조회 |
| idx_reservations_user | Reservations | user_id | 사용자별 예매 내역 조회 |
| idx_reservation_seats_reservation | Reservation_Seats | reservation_id | 예약별 예매 좌석 조회 |
| idx_reservation_seats_screening_seat | Reservation_Seats | screening_seat_id | 상영 좌석 기준 예매 상세 조회 |

---

## 2. 설계 이유

**① 반정규화(Denormalization)를 통한 조회 성능 최적화**
- `Reservations(예약)` 테이블에 `screening_id` 컬럼을 의도적으로 중복 배치(반정규화)했습니다.
- 정규화 원칙만 따지면 `Reservation_Seats`를 거쳐서 찾아가야 하지만, 영화관 서비스 특성상 고객이 자신의 '예매 내역'을 조회하는(읽기) 트래픽이 압도적으로 많습니다.
- 데이터 쓰기 시 미세한 중복이 발생하더라도, 마이페이지 등에서 조회할 때 발생하는 복잡한 3~4중 테이블 조인(Join) 비용을 줄여 **읽기 성능을 극대화**하기 위해 이와 같은 구조를 선택했습니다.

**② 마스터 데이터 무결성을 위한 복합 유니크(Composite Unique) 제약**
- `Theaters(상영관)` 테이블의 `(cinema_id, name)`처럼 마스터 데이터에 복합 유니크 제약을 걸었습니다.
- 지점, 상영관, 좌석 정보는 한 번 등록되면 거의 변하지 않는 정적 데이터입니다. 만약 관리자의 휴먼 에러로 상영관이 중복 등록되면 전체 예매 시스템에 치명적인 데이터 오염이 발생합니다.
- 이를 방지하기 위해 DB 레벨에서 최후의 방어막(Fail-fast)을 구축했으며, 쓰기 부하는 0에 가깝고 오히려 자동 생성되는 유니크 인덱스로 인해 **조회 속도가 향상**되는 이점을 고려했습니다.

**③ "데이터 저장(DB)"과 "비즈니스 통제(App)"의 책임 분리**
- `Reservation_Seats(예매 상세)`에서 단일 좌석의 중복 등록을 막는 `UNIQUE(screening_seat_id)` 제약을 과감히 제거했습니다.
- 사용자가 예매를 취소한 뒤 다른 사람이 그 자리를 다시 예매하려면 해당 좌석 ID가 여러 번 삽입(INSERT)될 수밖에 없기 때문입니다.
- 즉, 데이터베이스는 과거의 거래 영수증(스냅샷)을 영구히 쌓아두는 **'순수한 데이터 저장소'**의 역할만 담당하게 하고, 찰나의 순간에 동시 예매를 막아내는 **'비즈니스 통제 역할'은 애플리케이션 레벨(추후 Redis 분산 락 활용)로 완벽하게 책임을 분리**했습니다.

**④ 시간대 일관성과 변경 이력 추적**
- 서비스 운영 환경과 사용자 시간대가 달라져도 상영, 예약, 결제 시각을 일관되게 비교할 수 있도록 시간 컬럼을 `TIMESTAMPTZ`로 저장하고 UTC 기준으로 관리합니다.
- 변경 가능성이 있는 사용자, 상영 좌석, 예약, 결제 정보에는 `updated_at`을 두어 상태 변경 시점을 추적할 수 있도록 했습니다. 수정 시각 갱신은 애플리케이션에서 수행합니다.

**⑤ DB 제약조건과 조회 인덱스 보강**
- 가격·좌석 수·러닝타임의 범위와 상태값, 상영 종료 시각을 `CHECK` 제약으로 검증하여 잘못된 데이터가 저장되는 것을 DB 레벨에서 방지합니다.
- 영화별 상영 일정, 상영관별 시간순 일정, 사용자별 예매 내역처럼 빈번한 조회 경로에는 인덱스를 구성해 조인 및 조건 검색 비용을 줄였습니다.

## 3. 고민했던 부분
**① Reservation_Seats의 UNIQUE 제약 조건 제외와 동시성 제어**
- 처음에는 중복 예매를 확실하게 막기 위해 `Reservation_Seats.screening_seat_id`에 UNIQUE 제약을 두려 했습니다.
- 하지만 사용자가 예약을 취소한 뒤 다른 사용자가 해당 자리를 다시 예매하려고 할 때, 과거 취소 이력 때문에 Duplicate Key 에러가 발생하여 예매가 불가능해지는 치명적인 문제가 있음을 깨달았습니다.
- 따라서 과거 취소 이력(스냅샷 영수증)을 안전하게 영구 보존하기 위해 UNIQUE 제약을 제거했습니다. 이때 발생할 수 있는 동시성 문제(중복 예약)는 DB 제약조건이 아닌 **Redis 분산 락(Distributed Lock)**을 도입하여 애플리케이션 레벨에서 유연하고 안전하게 제어하기로 결정했습니다.

**② 예매 내역 조회를 위한 Reservations 테이블의 반정규화**
- `Reservations` 테이블에 `screening_id` 컬럼을 두는 것은 정규화 원칙상 중복입니다. (`Reservation_Seats`를 통해 찾아갈 수 있기 때문입니다.)
- 하지만 마이페이지 등에서 예매 내역을 조회할 때마다 불필요하게 여러 테이블을 조인(Join)해야 하는 성능 저하를 방지하기 위해, 의도적으로 `screening_id`를 `Reservations` 테이블로 빼두는 반정규화(Denormalization) 전략을 적용했습니다.

**③ 투트랙(Two-track) 전략을 통한 외부 노출용 식별자 분리**
- 외부 서비스(사용자, PG사)와 통신이 잦은 예약(`Reservations`) 테이블과 결제(`Payments`) 테이블은 식별자 설계 시 많은 고민이 있었습니다.
- 처음에는 UUID나 해시값을 테이블의 PK로 바로 쓰려 했으나, B-Tree 인덱스 특성상 정렬이 깨져 DB 조회 성능이 심각하게 저하될 우려가 있었습니다. 이에 따라 성능이 가장 좋은 순차적인 숫자 `id(BIGINT)`를 내부 식별자(PK)로 확정했습니다.
- 대신 고객에게 보여줄 예매번호(`reservation_number`)나 PG사 통신용 주문키(`payment_key`)를 `VARCHAR` 컬럼으로 따로 분리하여 추가하는 '투트랙 전략'을 채택했습니다. 이를 통해 **DB 성능 최적화와 외부 보안(비즈니스 규모 노출 방지)**이라는 두 마리 토끼를 모두 잡았습니다.
