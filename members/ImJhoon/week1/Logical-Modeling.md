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
| role | VARCHAR(ENUM) | NOT NULL, DEFAULT 'USER' | USER / ADMIN 등 |
| created_at | DATETIME | NOT NULL | 가입일시 |

## 2. Movies (영화)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 영화 고유 식별자 |
| title | VARCHAR | NOT NULL | 영화 제목 |
| running_time | INT | NOT NULL | 러닝타임(분) |
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
| total_seat_count | INT | NOT NULL | 전체 좌석 수 |

> **고려 사항:** 같은 지점 내에서 관 이름(`1관`, `2관`)이 중복되지 않도록 `(cinema_id, name)` 조합에 **복합 유니크 제약(Composite Unique Constraint)**을 거는 것을 고려해야 합니다. 
> - **휴먼 에러 방지:** 관리자의 중복 등록 실수로 인해 예매 시스템 전체에 치명적인 데이터 오염이 발생하는 것을 막는 최후의 방어막 역할을 합니다.
> - **성능 이점:** 마스터 데이터 특성상 쓰기(INSERT)가 드물어 유니크 제약으로 인한 부하는 사실상 없습니다. 오히려 이 제약조건이 자동 생성하는 인덱스 덕분에 특정 지점의 상영관을 조회(SELECT)할 때 성능이 향상됩니다.

## 5. Seats (좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 좌석 고유 식별자 |
| theater_id | BIGINT | FK(Theaters.id), NOT NULL | 소속 상영관 |
| seat_row | VARCHAR | NOT NULL | 좌석 열 (예: A) |
| seat_number | INT | NOT NULL | 좌석 번호 (예: 1) |
| seat_grade | VARCHAR(ENUM) | NOT NULL | 일반/프리미엄/커플석 등 |

> **고려 사항:** `(theater_id, seat_row, seat_number)` 조합에 UNIQUE 제약을 걸어 동일 상영관 내 좌석 중복을 방지하는 것을 고려해야 합니다.

## 6. Screenings (상영 일정)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 상영 일정 고유 식별자 |
| movie_id | BIGINT | FK(Movies.id), NOT NULL | 상영 영화 |
| theater_id | BIGINT | FK(Theaters.id), NOT NULL | 상영관 |
| start_time | DATETIME | NOT NULL | 상영 시작 시각 |
| end_time | DATETIME | NOT NULL | 상영 종료 시각 |
| base_price | INT | NOT NULL | 기본 요금 (시간대/조조 등 반영) |

> **고민 포인트:** 같은 상영관에서 시간이 겹치는 두 `Screenings`가 생성되면 안 되는데, 이건 제약조건만으로는 강제하기 어렵고 애플리케이션 레벨 검증이나 별도 정책이 필요합니다. 논리 모델 단계에서 한번 짚고 넘어가야 합니다.

## 7. Screening_Seats (상영 좌석)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 상영 좌석 고유 식별자 |
| screening_id | BIGINT | FK(Screenings.id), NOT NULL | 상영 일정 |
| seat_id | BIGINT | FK(Seats.id), NOT NULL | 물리 좌석 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'AVAILABLE' | AVAILABLE / HOLD / RESERVED |

> **고민 포인트:** PK를 별도 대리키로 둘지, `(screening_id, seat_id)` 복합키로 둘지 갈리는 지점입니다. 동시성 제어(비관적 락 등)를 고려하면 대리키 + UNIQUE(screening_id, seat_id) 조합이 다루기 편할 수 있습니다.

## 8. Reservations (예약)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 예약 고유 식별자 |
| reservation_number | VARCHAR | UNIQUE, NOT NULL | 고객 노출용 고유 예매번호 (예: A1B2C3D4) |
| user_id | BIGINT | FK(Users.id), NOT NULL | 예약자 |
| screening_id | BIGINT | FK(Screenings.id), NOT NULL | 예약 대상 상영 일정 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'PENDING' | PENDING / CONFIRMED / CANCELLED / EXPIRED |
| reserved_at | DATETIME | NOT NULL | 예약(선점) 시각 |
| expires_at | DATETIME | NULL | 결제 대기 만료 시각 |

> **고려 사항:** `screening_id`는 논리적으로 `Reservation_Seats`를 통해 접근할 수 있는 중복 데이터지만, 사용자의 예매 내역 조회 시 잦은 테이블 조인(Join)을 피하고 조회 성능을 최적화하기 위해 의도적으로 반정규화(Denormalization)하여 배치했습니다.

## 9. Reservation_Seats (예약 좌석 / 예매 상세)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 예약 좌석 고유 식별자 |
| reservation_id | BIGINT | FK(Reservations.id), NOT NULL | 소속 예약 |
| screening_seat_id | BIGINT | FK(Screening_Seats.id), NOT NULL | 지정된 상영 좌석 |
| seat_grade_snapshot | VARCHAR | NOT NULL | 예매 당시 좌석 등급 스냅샷 |
| price_snapshot | INT | NOT NULL | 예매 당시 가격 스냅샷 |
| cancel_status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'NONE' | 좌석 단위 취소 상태 |

> **고려 사항:** 취소된 좌석의 이력을 유지하면서 해당 좌석의 재예매가 가능해야 하므로 DB 레벨의 UNIQUE 제약은 걸지 않습니다. 동시 예약 방지는 DB 제약조건 대신 애플리케이션 레벨(추후 5주차 Redis 분산 락)에서 완벽하게 제어할 예정입니다.

## 10. Payments (결제)

| 속성명 | 타입(개념) | 제약조건 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | 결제 고유 식별자 |
| payment_key | VARCHAR | UNIQUE, NOT NULL | 외부 PG사 통신용 고유 결제 키 (주문번호) |
| reservation_id | BIGINT | FK(Reservations.id), NOT NULL, UNIQUE | 대상 예약 (1:0..1 관계 반영) |
| amount | INT | NOT NULL | 결제 금액 |
| method | VARCHAR(ENUM) | NOT NULL | 카드/간편결제 등 |
| status | VARCHAR(ENUM) | NOT NULL, DEFAULT 'PENDING' | PENDING / COMPLETED / FAILED / CANCELLED |
| paid_at | DATETIME | NULL | 결제 완료 시각 |

> **고려 사항:** `payment_key`는 포트원이나 토스페이먼츠 등 외부 결제(PG) 시스템과 통신할 때 내부 DB의 PK(`id`)를 직접 노출하지 않기 위해 투트랙(Two-track) 전략으로 분리한 난수/문자열 형태의 주문번호입니다.

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
