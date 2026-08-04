# Spring Security 세션 기반 초기 설정 학습 가이드

## 1. 문서 목적

이 문서는 Spring Security를 처음 접하는 입장에서 현재 프로젝트에 적용된 세션 기반 초기 설정을 이해하기 위한 학습 자료입니다.

현재 `security` 패키지에는 다음 파일이 있습니다.

```text
src/main/java/org/example/cinema/global/security
├─ SecurityConfig.java
└─ CsrfTokenController.java

src/test/java/org/example/cinema/global/security
└─ SecurityConfigTest.java
```

아직 실제 회원가입과 로그인 기능이 구현된 것은 아닙니다. 지금은 해당 기능을 구현하기 전에 Spring Security가 요청을 어떻게 허용하고 차단할지 준비한 상태입니다.

---

## 2. Spring Security의 요청 처리 위치

클라이언트 요청은 바로 Controller로 전달되지 않습니다. Spring Security를 사용하면 Controller 앞에 Security Filter Chain이 위치합니다.

```text
클라이언트 요청
        ↓
SecurityFilterChain
        ↓
공개 요청인가?
├─ 예 → Controller로 전달
└─ 아니요 → 로그인한 사용자인가?
             ├─ 예 → Controller로 전달
             └─ 아니요 → 401 Unauthorized 반환
```

`SecurityConfig`는 이 검사 과정에 적용할 규칙을 정의하는 파일입니다.

---

## 3. SecurityConfig.java

### 3.1 설정 클래스 선언

```java
@Configuration
public class SecurityConfig {}
```

`@Configuration`은 해당 클래스가 Spring 설정 클래스라는 뜻입니다. Spring은 애플리케이션을 실행할 때 이 클래스를 발견하고 내부의 `@Bean` 객체를 관리합니다.

### 3.2 공개할 POST 인증 API

```java
private static final String[] PUBLIC_AUTH_POST_ENDPOINTS = {
        "/api/v1/auth/signup",
        "/api/v1/auth/login"
};
```

회원가입과 로그인은 아직 인증되지 않은 사용자가 이용해야 하므로 공개 경로로 설정합니다.

```text
POST /api/v1/auth/signup
POST /api/v1/auth/login
```

여기서 주의할 점은 Security 설정이 API 자체를 만들어 주는 것은 아니라는 것입니다.

`permitAll()`은 다음 의미만 가집니다.

> 해당 URL을 처리하는 Controller가 존재한다면 인증되지 않은 사용자도 그 Controller까지 접근할 수 있다.

실제 회원가입 API를 만들려면 별도로 Controller와 Service를 구현해야 합니다.

### 3.3 공개할 GET 인증 API

```java
private static final String[] PUBLIC_AUTH_GET_ENDPOINTS = {
        "/api/v1/auth/check-email",
        "/api/v1/auth/check-nickname",
        "/api/v1/auth/csrf"
};
```

각 경로의 목적은 다음과 같습니다.

| 경로 | 목적 |
|---|---|
| `/api/v1/auth/check-email` | 이메일 중복 확인 |
| `/api/v1/auth/check-nickname` | 닉네임 중복 확인 |
| `/api/v1/auth/csrf` | CSRF 토큰 발급 |

이메일과 닉네임 중복 확인 API는 아직 구현하지 않았으며, 앞으로 구현할 경로를 미리 공개한 상태입니다.

### 3.4 Swagger와 OpenAPI 공개 경로

```java
private static final String[] PUBLIC_DOCUMENT_ENDPOINTS = {
        "/swagger-ui/**",
        "/v3/api-docs/**"
};
```

Swagger UI와 OpenAPI 문서는 로그인하지 않은 상태에서도 확인할 수 있도록 공개합니다.

`/**`는 해당 경로 아래에 있는 모든 하위 경로를 의미합니다.

```text
/swagger-ui/index.html
/swagger-ui/swagger-ui.css
/swagger-ui/swagger-ui-bundle.js
```

위 요청은 모두 `/swagger-ui/**` 규칙에 포함됩니다.

### 3.5 공개 조회 API

```java
private static final String[] PUBLIC_READ_ENDPOINTS = {
        "/api/v1/movies/**",
        "/api/v1/cinemas/**",
        "/api/v1/screenings/**"
};
```

영화, 영화관, 상영 일정은 로그인하지 않아도 조회할 수 있도록 준비했습니다.

이 경로는 이후 `HttpMethod.GET`과 함께 사용하므로 조회 요청만 공개됩니다.

```text
GET /api/v1/movies       → 공개
GET /api/v1/movies/1     → 공개
POST /api/v1/movies      → 공개되지 않음
DELETE /api/v1/movies/1  → 공개되지 않음
```

같은 URL이라도 HTTP 메서드에 따라 접근 규칙을 다르게 지정할 수 있습니다.

---

## 4. SecurityFilterChain 설정

### 4.1 SecurityFilterChain Bean

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http)
        throws Exception {}
```

`SecurityFilterChain`은 HTTP 요청을 검사하는 보안 필터들의 흐름입니다.

`HttpSecurity`는 다음과 같은 보안 규칙을 작성하기 위한 설정 도구입니다.

- 공개할 API
- 인증이 필요한 API
- 세션 생성 정책
- CSRF 보호
- 기본 로그인 방식 사용 여부
- 인증 실패 처리 방식

### 4.2 CSRF 설정

```java
.csrf(csrf -> csrf.spa())
```

현재 프로젝트는 세션과 쿠키를 사용하는 REST API이므로 CSRF 보호를 유지합니다.

#### CSRF가 필요한 이유

로그인에 성공하면 브라우저에 일반적으로 다음과 같은 세션 쿠키가 저장됩니다.

```http
JSESSIONID=abc123
```

브라우저는 서버에 요청할 때 세션 쿠키를 자동으로 전송합니다. 공격자는 이 특성을 이용해 사용자가 원하지 않은 요청을 보내도록 유도할 수 있습니다.

```text
사용자가 영화 사이트에 로그인
→ 브라우저에 JSESSIONID 저장
→ 사용자가 악성 사이트에 접속
→ 악성 사이트가 영화 사이트로 요청 전송
→ 브라우저가 JSESSIONID를 자동으로 첨부
```

서버는 세션 쿠키뿐 아니라 CSRF 토큰도 함께 검사하여 이런 요청을 방어합니다.

```text
유효한 세션 쿠키 + 유효한 CSRF 토큰
→ 정상 요청으로 판단
```

`spa()`는 REST API를 호출하는 SPA 클라이언트에서 쿠키와 헤더로 CSRF 토큰을 교환할 수 있도록 설정합니다.

### 4.3 기본 폼 로그인 비활성화

```java
.formLogin(AbstractHttpConfigurer::disable)
```

Spring Security는 기본적으로 HTML 로그인 화면을 제공할 수 있습니다. 현재 프로젝트는 JSON 요청을 받는 REST API이므로 기본 HTML 로그인 화면을 사용하지 않습니다.

향후 로그인 API는 다음 형태로 직접 구현할 예정입니다.

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

### 4.4 HTTP Basic 비활성화

```java
.httpBasic(AbstractHttpConfigurer::disable)
```

HTTP Basic은 요청마다 사용자 이름과 비밀번호를 HTTP 헤더에 담아 보내는 방식입니다.

```http
Authorization: Basic dXNlcjpwYXNzd29yZA==
```

현재 프로젝트는 로그인 성공 후 세션을 유지하는 방식을 사용할 것이므로 HTTP Basic을 비활성화했습니다.

### 4.5 기본 로그아웃 비활성화

```java
.logout(AbstractHttpConfigurer::disable)
```

Spring Security의 기본 `/logout` 경로는 사용하지 않습니다. 이후 프로젝트 API 명세에 맞는 다음 경로를 세션 무효화 기능과 함께 명시적으로 설정할 예정입니다.

```http
POST /api/v1/auth/logout
```

현재는 로그아웃 기능이 구현되지 않은 상태입니다.

### 4.6 Request Cache 비활성화

```java
.requestCache(AbstractHttpConfigurer::disable)
```

일반적인 웹 페이지 로그인에서는 사용자가 로그인 전에 방문하려던 페이지를 저장했다가 로그인 성공 후 다시 이동시킬 수 있습니다.

```text
/mypage 요청
→ 로그인 화면으로 이동
→ 로그인 성공
→ 원래 요청한 /mypage로 이동
```

REST API는 로그인 화면으로 이동시키지 않고 `401 Unauthorized` 상태를 반환하므로, 페이지 이동을 위한 요청 저장 기능을 비활성화했습니다.

### 4.7 세션 생성 정책

```java
.sessionManagement(session -> session
        .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED))
```

`IF_REQUIRED`는 세션이 필요한 경우에만 생성한다는 뜻입니다.

```text
비회원 영화 목록 조회 → 세션이 없어도 됨
로그인 성공           → 인증 정보를 보관할 세션이 필요함
```

로그인 기능이 구현되면 다음과 같은 흐름이 만들어집니다.

```text
로그인 성공
→ 서버가 세션 생성
→ 브라우저에 JSESSIONID 쿠키 발급
→ 이후 요청에 JSESSIONID 쿠키 전송
→ 서버가 로그인 사용자 확인
```

현재는 로그인 기능이 없으므로 실제 로그인 세션은 아직 만들어지지 않습니다.

### 4.8 인증 실패 시 401 반환

```java
.exceptionHandling(exception -> exception
        .authenticationEntryPoint(
                new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)
        ))
```

로그인하지 않은 사용자가 보호된 API를 호출하면 `401 Unauthorized`를 반환합니다.

```http
GET /api/v1/reservations

HTTP/1.1 401 Unauthorized
```

현재는 상태 코드만 반환합니다. 공통 예외 응답을 구현할 때 JSON 응답으로 확장할 수 있습니다.

```json
{
  "code": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
}
```

---

## 5. API 접근 규칙

### 5.1 오류 처리 요청 허용

```java
.dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
```

Spring 내부에서 오류 응답을 처리할 때 사용하는 요청이 Security에 의해 다시 차단되지 않도록 허용합니다.

입문 단계에서는 다음과 같이 이해하면 충분합니다.

> Spring이 원래 발생한 오류를 정상적으로 응답할 수 있도록 내부 오류 처리 요청을 허용한다.

### 5.2 회원가입과 로그인 허용

```java
.requestMatchers(
        HttpMethod.POST,
        PUBLIC_AUTH_POST_ENDPOINTS
).permitAll()
```

회원가입과 로그인은 인증되지 않은 사용자도 접근할 수 있습니다.

다만 `permitAll()`과 CSRF 검사는 서로 다른 규칙입니다.

```text
인증 검사 → permitAll이므로 통과
CSRF 검사 → 유효한 CSRF 토큰이 있어야 통과
```

따라서 공개된 회원가입 API라도 CSRF 토큰 없이 `POST` 요청을 보내면 `403 Forbidden`이 발생합니다.

### 5.3 중복 확인과 CSRF 발급 허용

```java
.requestMatchers(
        HttpMethod.GET,
        PUBLIC_AUTH_GET_ENDPOINTS
).permitAll()
```

이메일 중복 확인, 닉네임 중복 확인, CSRF 토큰 발급 요청은 로그인 없이 접근할 수 있습니다.

### 5.4 Swagger와 OpenAPI 허용

```java
.requestMatchers(PUBLIC_DOCUMENT_ENDPOINTS).permitAll()
```

Swagger UI와 OpenAPI 문서에 인증 없이 접근할 수 있도록 합니다.

### 5.5 영화 관련 조회 API 허용

```java
.requestMatchers(
        HttpMethod.GET,
        PUBLIC_READ_ENDPOINTS
).permitAll()
```

영화, 영화관, 상영 일정의 `GET` 요청을 공개합니다.

### 5.6 나머지 요청은 인증 필요

```java
.anyRequest().authenticated()
```

앞에서 공개하지 않은 모든 요청은 인증된 사용자만 접근할 수 있습니다.

```text
GET  /api/v1/reservations → 인증 필요
POST /api/v1/reservations → 인증 필요
GET  /api/v1/users/me     → 인증 필요
POST /api/v1/payments     → 인증 필요
```

현재는 실제 로그인 기능이 없으므로 클라이언트가 이 API에 접근할 방법은 아직 없습니다. 로그인과 세션 저장 기능을 구현한 후 접근할 수 있습니다.

---

## 6. PasswordEncoder

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

`PasswordEncoder`는 사용자의 비밀번호를 안전한 형태로 변환하고 비교하는 객체입니다.

비밀번호를 DB에 평문으로 저장하면 안 됩니다.

```text
잘못된 예
password = "password123!"
```

회원가입 시 BCrypt로 변환한 값을 저장합니다.

```java
String encodedPassword =
        passwordEncoder.encode(request.password());
```

DB에는 다음과 유사한 값이 저장됩니다.

```text
$2a$10$...
```

로그인 시에는 암호화된 값을 복호화하지 않고 사용자가 입력한 비밀번호와 일치하는지 검사합니다.

```java
boolean matches = passwordEncoder.matches(
        rawPassword,
        encodedPassword
);
```

---

## 7. CsrfTokenController.java

### 7.1 Controller 선언

```java
@RestController
@RequestMapping("/api/v1/auth")
public class CsrfTokenController {
```

`@RestController`는 메서드의 반환값을 JSON 응답으로 전달한다는 뜻입니다.

`@RequestMapping("/api/v1/auth")`는 이 Controller의 모든 API에 공통 URL을 지정합니다.

### 7.2 CSRF 토큰 발급

```java
@GetMapping("/csrf")
public CsrfToken csrf(CsrfToken csrfToken) {
    return csrfToken;
}
```

최종 API 경로는 다음과 같습니다.

```http
GET /api/v1/auth/csrf
```

`CsrfToken`은 Spring Security가 생성하여 Controller 메서드에 전달합니다. 응답은 다음과 유사합니다.

```json
{
  "headerName": "X-XSRF-TOKEN",
  "parameterName": "_csrf",
  "token": "발급된 토큰 값"
}
```

응답과 함께 `XSRF-TOKEN` 쿠키도 발급됩니다.

```http
Set-Cookie: XSRF-TOKEN=발급된-토큰-값
```

프론트엔드는 이후 상태를 변경하는 요청에 해당 값을 헤더로 전달합니다.

```http
X-XSRF-TOKEN: 발급된-토큰-값
```

회원가입 요청의 전체 흐름은 다음과 같습니다.

```text
1. GET /api/v1/auth/csrf
2. XSRF-TOKEN 쿠키 발급
3. POST /api/v1/auth/signup 요청
4. X-XSRF-TOKEN 헤더 전달
5. Spring Security가 CSRF 토큰 검증
6. 회원가입 Controller 실행
```

---

## 8. SecurityConfigTest.java

### 8.1 입문 단계에서도 테스트가 필요한가?

테스트 자체는 입문 단계에서도 필요합니다. 다만 현재 테스트의 모든 세부 구현을 처음부터 완벽하게 이해할 필요는 없습니다.

Spring Security 설정은 작은 실수로도 다음 문제가 발생할 수 있습니다.

- 회원가입 API가 인증 요구로 인해 차단됨
- 보호되어야 할 예약 API가 공개됨
- CSRF 보호가 적용되지 않음
- 비밀번호가 평문으로 저장됨

테스트는 이런 설정 실수를 자동으로 발견하는 안전장치입니다.

입문 단계에서는 우선 다음 세 가지를 이해하는 것을 목표로 합니다.

1. 공개 API는 인증 없이 접근할 수 있어야 한다.
2. 보호 API는 인증 없이 접근하면 `401`이어야 한다.
3. 비밀번호는 평문과 다른 값으로 암호화되어야 한다.

### 8.2 테스트 설정

```java
@WebMvcTest(
    controllers = {
        CsrfTokenController.class,
        SecurityTestController.class
    }
)
@Import(SecurityConfig.class)
```

- `@WebMvcTest`: 전체 애플리케이션 대신 웹 계층을 중심으로 테스트합니다.
- `@Import(SecurityConfig.class)`: 실제 Security 설정을 테스트에 포함합니다.

### 8.3 MockMvc

```java
@Autowired
private MockMvc mockMvc;
```

`MockMvc`는 서버를 실제로 실행하지 않고 HTTP 요청을 흉내 내는 테스트 도구입니다.

```java
mockMvc.perform(get("/api/v1/movies"));
```

위 코드는 다음 HTTP 요청을 테스트에서 실행하는 것과 같습니다.

```http
GET /api/v1/movies
```

### 8.4 CSRF 토큰 발급 테스트

```java
mockMvc.perform(get("/api/v1/auth/csrf"))
        .andExpect(status().isOk())
        .andExpect(cookie().exists("XSRF-TOKEN"))
        .andExpect(jsonPath("$.headerName")
                .value("X-XSRF-TOKEN"))
        .andExpect(jsonPath("$.token").isNotEmpty());
```

다음 내용을 검사합니다.

- 응답 상태가 `200 OK`인가?
- `XSRF-TOKEN` 쿠키가 발급되는가?
- 요청에 사용할 헤더 이름이 `X-XSRF-TOKEN`인가?
- 토큰 값이 비어 있지 않은가?

### 8.5 공개 API 테스트

```java
mockMvc.perform(get("/api/v1/movies"))
        .andExpect(status().isOk());
```

로그인하지 않은 사용자도 영화 조회 API에 접근할 수 있는지 확인합니다.

### 8.6 보호 API 테스트

```java
mockMvc.perform(get("/api/v1/reservations"))
        .andExpect(status().isUnauthorized());
```

로그인하지 않은 사용자가 예약 API에 접근하면 `401 Unauthorized`가 반환되는지 확인합니다.

### 8.7 인증된 사용자 테스트

```java
mockMvc.perform(
        get("/api/v1/reservations")
                .with(user("member"))
)
.andExpect(status().isOk());
```

`user("member")`는 실제 로그인 기능이 아닙니다. 테스트 안에서만 `member`라는 사용자가 로그인했다고 가정하는 기능입니다.

### 8.8 CSRF 검사 테스트

CSRF 토큰 없이 회원가입을 요청하면 `403 Forbidden`이 반환되는지 확인합니다.

```java
mockMvc.perform(post("/api/v1/auth/signup")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{}"))
        .andExpect(status().isForbidden());
```

그다음 실제 브라우저의 동작과 비슷하게 CSRF 토큰을 발급받습니다.

```java
MvcResult csrfResult =
        mockMvc.perform(get("/api/v1/auth/csrf"))
                .andExpect(status().isOk())
                .andReturn();

Cookie csrfCookie =
        csrfResult.getResponse().getCookie("XSRF-TOKEN");
```

발급된 쿠키 값과 헤더를 회원가입 요청에 포함합니다.

```java
mockMvc.perform(post("/api/v1/auth/signup")
        .cookie(csrfCookie)
        .header("X-XSRF-TOKEN", csrfCookie.getValue())
        .contentType(MediaType.APPLICATION_JSON)
        .content("{}"))
        .andExpect(status().isOk());
```

입문 단계에서는 이 코드 전체를 외우기보다 다음 원리만 이해하면 충분합니다.

```text
GET 요청    → 일반적으로 CSRF 토큰이 필요하지 않음
POST 요청   → CSRF 토큰 필요
토큰 없음   → 403 Forbidden
토큰 있음   → Security의 CSRF 검사 통과
```

### 8.9 PasswordEncoder 테스트

```java
String rawPassword = "spring-security-password";
String encodedPassword =
        passwordEncoder.encode(rawPassword);

assertThat(encodedPassword)
        .isNotEqualTo(rawPassword);

assertThat(passwordEncoder.matches(
        rawPassword,
        encodedPassword
)).isTrue();
```

다음 두 가지를 확인합니다.

- 암호화 결과가 평문 비밀번호와 다른가?
- 평문과 암호화된 값을 비교했을 때 일치한다고 판단하는가?

### 8.10 SecurityTestController

테스트 파일 아래에 있는 `SecurityTestController`는 Security 설정을 검사하기 위한 가짜 Controller입니다.

```java
@RestController
class SecurityTestController {
```

현재 실제 영화, 예약, 회원가입 Controller가 없기 때문에 테스트 안에서만 사용할 API를 제공합니다.

```java
@GetMapping("/api/v1/movies")
String movies() {
    return "movies";
}
```

공개 조회 API를 테스트합니다.

```java
@GetMapping("/api/v1/reservations")
String reservations() {
    return "reservations";
}
```

인증이 필요한 API를 테스트합니다.

```java
@PostMapping("/api/v1/auth/signup")
String signup() {
    return "signup";
}
```

회원가입 경로의 공개 여부와 CSRF 검사를 테스트합니다.

이 Controller는 `src/test` 안에 있으므로 실제 애플리케이션을 실행할 때는 포함되지 않습니다.

---

## 9. 입문 단계에서 필요한 최소 테스트

현재 테스트를 모두 직접 작성하는 것이 어렵다면 다음 세 종류를 우선 이해하면 됩니다.

### 9.1 공개 API 접근 테스트

```java
@Test
void 공개_API는_인증_없이_접근할_수_있다() throws Exception {
    mockMvc.perform(get("/api/v1/movies"))
            .andExpect(status().isOk());
}
```

### 9.2 보호 API 차단 테스트

```java
@Test
void 보호_API는_인증_없이_접근할_수_없다() throws Exception {
    mockMvc.perform(get("/api/v1/reservations"))
            .andExpect(status().isUnauthorized());
}
```

### 9.3 비밀번호 암호화 테스트

```java
@Test
void 비밀번호를_BCrypt로_암호화할_수_있다() {
    String rawPassword = "password123!";
    String encodedPassword = passwordEncoder.encode(rawPassword);

    assertThat(encodedPassword).isNotEqualTo(rawPassword);
    assertThat(passwordEncoder.matches(rawPassword, encodedPassword))
            .isTrue();
}
```

테스트를 완전히 제외하기보다는 기능 하나를 구현할 때 간단한 테스트 하나씩 추가하는 방법을 권장합니다.

---

## 10. 현재 구현 상태

### 완료된 부분

- Security Filter Chain 등록
- 공개 API와 보호 API 구분
- 필요할 때 세션을 생성하는 정책
- 세션 방식에 필요한 CSRF 보호
- CSRF 토큰 발급 API
- BCrypt `PasswordEncoder` Bean
- Security 설정 테스트

### 아직 구현하지 않은 부분

- 실제 회원가입 Controller
- 회원가입 Service
- 사용자 Repository
- DB 기반 `UserDetailsService`
- 실제 로그인 API
- `AuthenticationManager` 연동
- 로그인 성공 후 SecurityContext와 세션 저장
- 세션 로그아웃

---

## 11. 우선 기억할 핵심

입문 단계에서는 다음 내용을 먼저 기억합니다.

1. `SecurityFilterChain`은 Controller 앞에서 요청을 검사합니다.
2. `permitAll()`은 API를 만드는 것이 아니라 해당 경로에 대한 접근만 허용합니다.
3. `authenticated()`는 로그인한 사용자만 접근할 수 있다는 뜻입니다.
4. 세션 방식은 브라우저 쿠키를 사용하므로 CSRF 보호가 중요합니다.
5. 비밀번호는 `PasswordEncoder`를 사용해 암호화한 후 저장합니다.
6. 테스트는 공개 경로와 보호 경로가 의도대로 동작하는지 확인하는 안전장치입니다.

다음 회원가입 구현 단계에서는 전체 Security 설정을 다시 다루기보다 `PasswordEncoder`를 Service에 주입하고 비밀번호를 암호화해 저장하는 과정부터 학습합니다.
