# 영화 예매 시스템 API 명세서

## 1. 공통 사항

- Base URL: `/api/v1`
- 요청과 응답 형식: `application/json`
- 인증이 필요한 API는 `Authorization: Bearer {accessToken}` 헤더를 사용한다.
- 날짜와 시간은 ISO 8601 형식을 사용한다.

### 공통 응답 형식

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

### 공통 오류 응답

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "오류 메시지"
  }
}
```

## 2. API 목록

### 인증

| Method | URI | 기능 | 인증 | 주요 요청값 |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/signup` | 회원가입 | 불필요 | 이메일, 비밀번호, 닉네임 |
| POST | `/api/v1/auth/login` | 로그인 | 불필요 | 이메일, 비밀번호 |
| POST | `/api/v1/auth/logout` | 로그아웃 | 필요 | - |

### 영화 및 상영 일정

| Method | URI | 기능 | 인증 | 주요 요청값 |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/movies` | 영화 목록 조회 | 불필요 | - |
| GET | `/api/v1/movies/{movieId}` | 영화 상세 조회 | 불필요 | `movieId` |
| GET | `/api/v1/movies/{movieId}/screenings` | 영화별 상영 일정 조회 | 불필요 | `movieId`, 날짜 |
| GET | `/api/v1/theaters` | 영화관 목록 조회 | 불필요 | - |

### 좌석 및 선점

| Method | URI | 기능 | 인증 | 주요 요청값 |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/screenings/{screeningId}/seats` | 상영 좌석 조회 | 불필요 | `screeningId` |
| POST | `/api/v1/screenings/{screeningId}/seats/hold` | 좌석 임시 선점 | 필요 | `screeningId`, 좌석 ID 목록 |
| DELETE | `/api/v1/seat-holds/{holdToken}` | 좌석 선점 해제 | 필요 | `holdToken` |

### 예매

| Method | URI | 기능 | 인증 | 주요 요청값 |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/reservations` | 예매 생성 | 필요 | 상영 일정 ID, 좌석 ID 목록, 선점 토큰 |
| GET | `/api/v1/members/me/reservations` | 내 예매 목록 조회 | 필요 | - |
| GET | `/api/v1/reservations/{reservationId}` | 예매 상세 조회 | 필요 | `reservationId` |
| POST | `/api/v1/reservations/{reservationId}/cancel` | 예매 취소 | 필요 | `reservationId` |

## 3. 주요 상태 코드

| 상태 코드 | 의미 |
| --- | --- |
| 200 OK | 조회, 로그인, 로그아웃, 취소 성공 |
| 201 Created | 회원가입, 좌석 선점, 예매 생성 성공 |
| 204 No Content | 좌석 선점 해제 성공 |
| 400 Bad Request | 요청값 또는 비즈니스 규칙 위반 |
| 401 Unauthorized | 인증 정보가 없거나 유효하지 않음 |
| 403 Forbidden | 본인 소유가 아닌 예매에 접근 |
| 404 Not Found | 영화, 상영 일정, 좌석 또는 예매를 찾을 수 없음 |
| 409 Conflict | 이메일 중복, 좌석 선점 또는 예매 충돌 |
