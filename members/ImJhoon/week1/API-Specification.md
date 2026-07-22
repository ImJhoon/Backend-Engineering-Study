# [Week 1] 프로젝트 고유 API 명세서

`Project-Requirements.md`의 요구사항(UR-USER, UR-MOVIE, UR-CINEMA, UR-SCREEN, UR-RSV, UR-PAY, UR-CNL)을 완벽하게 충족하기 위해 설계된 RESTful API 엔드포인트 명세서입니다.

---

##  0. 전역 정책 (Global Policies)

### 0.1 인증 방식 (Authentication)
* **방식:** JWT (JSON Web Token) 기반 Bearer 인증
* **사용법:** 인증이 필요한 모든 API 호출 시 HTTP Header에 토큰 포함 
  * `Authorization: Bearer <Access_Token>`
* **예외 처리:** 만료된 토큰이거나 유효하지 않은 경우 `401 Unauthorized` 반환

### 0.2 예매 취소 및 부분 취소 방침 (Cancellation Policy)
* `UR-CNL-001`에 따라 확정된 예매를 취소할 수 있습니다.
* `UR-CNL-002`에 따라 취소 시 좌석 단위의 취소 이력(`cancel_status`)이 `reservation_seats` 스냅샷 테이블에 영구 보존됩니다.

---

## 1. 인증 및 사용자 (Auth & Users) 도메인 

* **`POST /api/v1/auth/signup`**
  * **설명:** 회원가입을 진행합니다. (UR-USER-001)
  * **Body:** `email`, `password`, `password_confirm`, `nickname`, `name`, `phone` (UR-USER-002)
  * **검증:** 이메일 형식/중복, 비밀번호 복잡도/일치, 닉네임 길이/중복 검증 수행. (UR-USER-003)
* **`GET /api/v1/auth/check-email`**
  * **설명:** 이메일 중복 여부를 확인합니다.
  * **Query:** `?email=test@test.com`
* **`GET /api/v1/auth/check-nickname`**
  * **설명:** 닉네임 중복 여부를 확인합니다.
  * **Query:** `?nickname=testname`
* **`POST /api/v1/auth/login`**
  * **설명:** 이메일과 비밀번호를 통해 로그인을 수행하고 **Access Token** 및 **Refresh Token**을 발급합니다.
  * **Body:** `email`, `password`
* **`POST /api/v1/auth/logout`**
  * **설명:** 현재 클라이언트의 인증 정보(Refresh Token)를 서버에서 무효화하고 로그아웃합니다.
* **`GET /api/v1/users/me`**
  * **설명:** 현재 로그인한 사용자의 정보를 조회하여 세션 유효성을 확인하고 상태를 유지합니다. 역할(`role`) 정보도 포함됩니다. (UR-USER-004)

---

## 2. 영화 (Movies) 도메인

* **`GET /api/v1/movies`**
  * **설명:** 현재 상영 중인 영화 목록을 카드 형태로 제공하기 위해 조회합니다. (UR-MOVIE-001)
  * **Query:** `?page=1&size=20&keyword=오펜하이머` (페이지네이션 및 키워드 검색 지원)
  * **Response:** 포스터 URL, 제목, 관람 등급 등 기본 정보 배열 및 `total_pages`
* **`GET /api/v1/movies/{movieId}`**
  * **설명:** 선택한 영화의 상세 정보(줄거리, 감독, 출연진 등)를 조회합니다.

---

## 3. 상영 일정 및 상영관 (Screenings & Cinemas) 도메인

* **`GET /api/v1/cinemas`**
  * **설명:** 예매 가능한 전국 영화관 지점 목록을 조회합니다. (UR-CINEMA-001)
  * **Query:** `?page=1&size=20` (지점이 많을 경우를 대비한 페이지네이션)
* **`GET /api/v1/screenings`**
  * **설명:** 특정 조건(영화, 지점, 날짜)에 맞는 상영 일정(시간표) 및 상영관 정보, 잔여 좌석 수를 조회합니다. (UR-SCREEN-001, 002)
  * **Query:** `?movie_id=1&cinema_id=10&date=2024-03-01`
* **`GET /api/v1/screenings/{screeningId}`**
  * **설명:** 특정 상영 일정의 상세 정보를 조회합니다.

---

## 4. 상영 좌석 (Screening Seats) 도메인

* **`GET /api/v1/screenings/{screeningId}/seats`**
  * **설명:** 특정 상영 일정의 전체 좌석 배치도와 물리적 좌석 등급(UR-THEATER-001), 그리고 실시간 좌석 상태(`AVAILABLE`, `HOLD`, `RESERVED`)를 조회합니다.

---

## 5. 예매 (Reservations) 도메인

* **`POST /api/v1/reservations`**
  * **설명:** 로그인한 사용자가 선택한 좌석에 대해 임시 예매(선점)를 생성합니다. 상태는 `PENDING`이 되며, 결제 대기 시간(`expires_at`)이 부여됩니다. (UR-RSV-001, 002)
  * **Header:** `Idempotency-Key` (네트워크 재시도 시 중복 선점 방지)
  * **Body:** `screening_id`, `screening_seat_ids` (선택된 좌석 배열)
  * **비즈니스 로직 적용:**
    * 다수 동시 요청 시 분산 락(Redis Lock) 등을 통해 최초 완료자에게만 선점 권한 부여 (UR-RSV-003). 좌석 상태는 `HOLD`로 변경.
    * 응답으로 `reservation_id`와 `expires_at` 반환.
* **`GET /api/v1/reservations/{reservationId}`**
  * **설명:** 특정 예매의 상세 내역, 스냅샷으로 저장된 선점 좌석 정보 및 가격(UR-RSV-004), 결제 만료 시간 등을 조회합니다.
* **`GET /api/v1/users/me/reservations`**
  * **설명:** 현재 로그인한 사용자의 전체 예매 내역 목록을 최신순으로 조회합니다. (UR-RSV-005)
  * **Query:** `?page=1&size=10`
* **`DELETE /api/v1/reservations/{reservationId}`**
  * **설명:** 예매를 취소합니다. (UR-CNL-001) 확정된 예매 취소 시 `reservations` 상태는 `CANCELLED`로 변경되며, 좌석들의 상태는 `AVAILABLE`로 복구되고 `reservation_seats.cancel_status`가 업데이트됩니다. (UR-CNL-002)

---

## 6. 결제 (Payments) 도메인 (PG사 연동)

* **`POST /api/v1/payments/confirm`**
  * **설명:** 클라이언트가 PG사 결제를 진행한 뒤 받아온 `payment_key`를 서버에 전달하여 금액을 재검증하고 예매를 최종 확정(`CONFIRMED`)합니다. (UR-PAY-001, 002)
  * **Header:** `Idempotency-Key` (중복 결제 및 예매 확정 방지 - UR-PAY-003)
  * **Body:** `reservation_id`, `payment_key`, `amount` (결제 요청 금액)
  * **비즈니스 로직 적용:**
    * `reservations.expires_at` 만료 여부 검증.
    * PG사 승인 API 연동 후 금액 불일치 시 예외 처리.
    * 성공 시 `reservations`를 `CONFIRMED`로, `screening_seats`를 `RESERVED`로 변경 및 스냅샷 확정.

---

## ⚠️ 7. 공통 에러 응답 스키마 (Error Response Schema)

클라이언트가 비즈니스 예외 상황을 분기 처리할 수 있도록, 실패 시 다음과 같은 표준화된 에러 JSON 포맷을 반환합니다.

```json
{
  "success": false,
  "error_code": "SEAT_ALREADY_TAKEN",
  "message": "이미 다른 사용자가 선점한 좌석입니다.",
  "status": 409
}
```
**[주요 예외 코드 예시]**
* `SEAT_ALREADY_TAKEN` (409): 결제/선점 중 타인이 먼저 좌석 선점 완료
* `PAYMENT_VALIDATION_FAILED` (400): PG사 결제 금액과 실제 예매 금액 불일치
* `RESERVATION_EXPIRED` (400): 결제 대기 시간 초과로 인한 자동 만료

---

##  API 엔드포인트 리스트
- `POST /api/v1/auth/signup` (회원가입)
- `GET /api/v1/auth/check-email` (이메일검증)
- `GET /api/v1/auth/check-nickname` (닉네임검증)
- `POST /api/v1/auth/login` (로그인)
- `POST /api/v1/auth/logout` (로그아웃)
- `GET /api/v1/users/me` (내정보조회)
- `GET /api/v1/movies` (영화목록)
- `GET /api/v1/movies/{movieId}` (영화상세)
- `GET /api/v1/cinemas` (극장목록)
- `GET /api/v1/screenings` (상영시간표)
- `GET /api/v1/screenings/{screeningId}` (시간표상세)
- `GET /api/v1/screenings/{screeningId}/seats` (좌석조회)
- `POST /api/v1/reservations` (좌석선점(예약))
- `GET /api/v1/reservations/{reservationId}` (예매상세)
- `GET /api/v1/users/me/reservations` (예매내역)
- `DELETE /api/v1/reservations/{reservationId}` (예매취소)
- `POST /api/v1/payments/confirm` (결제승인)

---
