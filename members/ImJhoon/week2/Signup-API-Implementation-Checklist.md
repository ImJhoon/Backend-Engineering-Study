# 회원가입 API 구현 체크리스트

## 목표

다음 회원가입 API를 구현합니다.

```http
POST /api/v1/auth/signup
Content-Type: application/json
```

회원가입이 성공하면 사용자의 비밀번호를 BCrypt로 암호화하고 기본 권한 `USER`로 저장합니다.

---

## 1. 구현 전 확인

- [x] 현재 Security 설정에서 `POST /api/v1/auth/signup`이 `permitAll()`인지 확인한다.
- [x] 세션 방식이므로 회원가입 `POST` 요청에도 CSRF 토큰이 필요하다는 것을 확인한다.
- [x] `PasswordEncoder` Bean이 등록되어 있는지 확인한다.
- [x] `users` 테이블의 실제 스키마와 `User` 엔티티가 일치하는지 확인한다.
- [x] 회원가입 요청과 응답 형식을 API 명세에서 확인한다.
- [x] 이메일, 닉네임, 전화번호를 고유값으로 관리한다.

---

## 2. User 엔티티 점검

- [x] `email` 필드가 필수값인지 확인한다.
- [x] `password` 필드가 암호화된 비밀번호를 저장할 충분한 길이인지 확인한다.
- [x] `name` 필드의 최대 길이를 확인한다.
- [x] `nickname` 필드가 필수값인지 확인한다.
- [x] `phone` 필드가 필수값인지 확인한다.
- [x] `role` 필드의 기본값을 서버에서 `USER`로 지정한다.
- [x] `createdAt`이 회원 저장 시 자동으로 생성되는지 확인한다.
- [x] 이메일에 DB `UNIQUE` 제약조건이 있는지 확인한다.
- [x] 닉네임에 DB `UNIQUE` 제약조건이 있는지 확인한다.
- [x] 전화번호에 DB `UNIQUE` 제약조건이 있는지 확인한다.
- [ ] 애플리케이션의 중복 검사와 별개로 DB 제약조건이 필요한 이유를 이해한다.

### 엔티티 생성 방식

- [x] Controller나 Service에서 Setter를 여러 번 호출하는 대신 생성자 또는 정적 팩토리 메서드 사용을 검토한다.
- [x] 회원가입 요청으로 `role`을 직접 받지 않는다.
- [x] 외부 사용자가 `ADMIN` 권한을 지정할 수 없도록 한다.

예시:

```java
public static User create(
        String email,
        String encodedPassword,
        String name,
        String nickname,
        String phone
) {
    User user = new User();
    user.email = email;
    user.password = encodedPassword;
    user.name = name;
    user.nickname = nickname;
    user.phone = phone;
    user.role = "USER";
    return user;
}
```

---

## 3. UserRepository 구현

- [x] `UserRepository`가 `JpaRepository<User, Long>`를 상속하도록 작성한다.
- [x] 이메일 중복 확인 메서드를 작성한다.
- [x] 닉네임 중복 확인 메서드를 작성한다.
- [x] 전화번호 중복 확인 메서드를 작성한다.

예시:

```java
public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByEmail(String email);

    boolean existsByNickname(String nickname);

    boolean existsByPhone(String phone);
}
```

---

## 4. 회원가입 요청 DTO 구현

- [x] Entity를 Controller의 요청 객체로 직접 사용하지 않는다.
- [x] `SignupRequest` DTO를 작성한다.
- [x] 이메일에 `@NotBlank`를 적용한다.
- [x] 이메일에 `@Email`을 적용한다.
- [x] 비밀번호에 `@NotBlank`를 적용한다.
- [x] 비밀번호 최소·최대 길이를 결정하고 `@Size`를 적용한다.
- [x] 이름에 필요한 검증 조건을 적용한다.
- [x] 닉네임에 필요한 검증 조건을 적용한다.
- [x] 전화번호에 필요한 검증 조건을 적용한다.
- [x] DTO에 `role` 필드를 포함하지 않는다.

예시:

```java
public record SignupRequest(
        @NotBlank
        @Email
        @Size(max = 100)
        String email,

        @NotBlank
        @Size(min = 8, max = 64)
        String password,

        @JsonProperty("password_confirm")
        @NotBlank
        @Size(min = 8, max = 64)
        String passwordConfirm,

        @NotBlank
        @Size(max = 12)
        String nickname,

        @NotBlank
        @Size(max = 20)
        String name,

        @NotBlank
        @Pattern(regexp = "^010-\\d{4}-\\d{4}$")
        String phone
) {
}
```

### 검증 규칙 결정

- [ ] 비밀번호에 영문, 숫자, 특수문자 조합을 강제할지 결정한다.
- [ ] 이메일을 저장하기 전에 소문자로 정규화할지 결정한다.
- [ ] 이메일 앞뒤 공백을 제거할지 결정한다.
- [ ] 닉네임 앞뒤 공백을 제거할지 결정한다.
- [x] 전화번호 저장 형식을 `010-0000-0000`으로 결정한다.

---

## 5. 회원가입 응답 DTO 구현

- [x] `SignupResponse` DTO를 작성한다.
- [x] 응답에 생성된 회원 ID를 포함할지 결정한다.
- [x] 응답에 이메일이나 닉네임을 포함할지 결정한다.
- [x] 응답에 비밀번호를 절대 포함하지 않는다.
- [x] 응답에 불필요한 개인정보를 포함하지 않는다.

예시:

```java
public record SignupResponse(Long userId) {
}
```

성공 응답 예시:

```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "userId": 1
}
```

---

## 6. 회원가입 Service 구현

- [x] 회원가입 로직을 담당할 Service를 작성한다.
- [x] Service에 `UserRepository`를 주입한다.
- [x] Service에 `PasswordEncoder`를 주입한다.
- [x] 회원가입 메서드에 `@Transactional`을 적용한다.
- [x] 이메일 중복 여부를 확인한다.
- [x] 닉네임 중복 여부를 확인한다.
- [x] 전화번호 중복 여부를 확인한다.
- [x] 중복이면 적절한 예외를 발생시킨다.
- [x] 평문 비밀번호를 `PasswordEncoder`로 암호화한다.
- [x] 기본 권한을 `USER`로 설정한다.
- [x] 사용자 Entity를 저장한다.
- [x] 저장된 사용자의 ID 또는 응답 DTO를 반환한다.

권장 처리 순서:

```text
요청값 검증
→ 이메일 중복 확인
→ 닉네임 중복 확인
→ 비밀번호 암호화
→ 기본 권한 USER 설정
→ User 저장
→ 회원가입 결과 반환
```

예시:

```java
@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public Long signup(SignupRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new DuplicateEmailException();
        }

        if (userRepository.existsByNickname(request.nickname())) {
            throw new DuplicateNicknameException();
        }

        User user = User.create(
                request.email(),
                passwordEncoder.encode(request.password()),
                request.name(),
                request.nickname(),
                request.phone()
        );

        return userRepository.save(user).getId();
    }
}
```

---

## 7. 회원가입 Controller 구현

- [x] 인증 관련 Controller의 기본 경로를 `/api/v1/auth`로 설정한다.
- [x] `POST /signup` 메서드를 작성한다.
- [x] 요청 DTO에 `@RequestBody`를 적용한다.
- [x] 요청 DTO에 `@Valid`를 적용한다.
- [x] Controller는 회원가입 업무 로직을 직접 처리하지 않고 Service를 호출한다.
- [x] 회원가입 성공 시 `201 Created`를 반환한다.
- [x] 응답 DTO를 반환한다.
- [x] 비밀번호를 응답에 포함하지 않는다.

예시:

```java
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<SignupResponse> signup(
            @Valid @RequestBody SignupRequest request
    ) {
        Long userId = userService.signup(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(new SignupResponse(userId));
    }
}
```

---

## 8. 예외 처리

- [x] 중복 이메일 예외를 정의한다.
- [x] 중복 닉네임 예외를 정의한다.
- [x] 중복 전화번호 예외를 정의한다.
- [x] Validation 실패를 `400 Bad Request`로 처리한다.
- [x] 중복 회원 정보는 `409 Conflict`로 처리한다.
- [x] 예외 응답 형식을 프로젝트 전체에서 일관되게 정의한다.
- [x] 내부 예외 메시지나 스택 트레이스를 클라이언트에 노출하지 않는다.

권장 상태 코드:

| 상황 | 상태 코드 |
|---|---:|
| 회원가입 성공 | `201 Created` |
| 요청값 검증 실패 | `400 Bad Request` |
| CSRF 토큰 누락 또는 불일치 | `403 Forbidden` |
| 이메일·닉네임 중복 | `409 Conflict` |
| 예상하지 못한 서버 오류 | `500 Internal Server Error` |

예외 응답 예시:

```json
{
  "success": false,
  "error_code": "DUPLICATE_EMAIL",
  "message": "이미 사용 중인 이메일입니다.",
  "status": 409
}
```

---

## 9. 회원가입 Service 테스트

- [x] 정상 요청이면 사용자가 저장되는지 테스트한다.
- [x] 저장된 비밀번호가 평문과 다른지 테스트한다.
- [x] `PasswordEncoder.matches()`로 저장된 비밀번호를 검증한다.
- [x] 저장된 기본 권한이 `USER`인지 테스트한다.
- [x] 이메일이 중복되면 예외가 발생하는지 테스트한다.
- [x] 닉네임이 중복되면 예외가 발생하는지 테스트한다.
- [x] 전화번호가 중복되면 예외가 발생하는지 테스트한다.
- [x] 중복 검사가 실패하면 사용자가 저장되지 않는지 테스트한다.

---

## 10. 회원가입 Controller/API 테스트

- [x] 정상적인 회원가입 요청이 `201 Created`를 반환하는지 테스트한다.
- [x] 응답에 생성된 회원 ID가 포함되는지 테스트한다.
- [x] 응답에 비밀번호가 포함되지 않는지 테스트한다.
- [x] 잘못된 이메일 형식이 `400 Bad Request`를 반환하는지 테스트한다.
- [x] 빈 비밀번호가 `400 Bad Request`를 반환하는지 테스트한다.
- [x] 비밀번호 길이 규칙 위반이 `400 Bad Request`를 반환하는지 테스트한다.
- [x] 필수값 누락이 `400 Bad Request`를 반환하는지 테스트한다.
- [x] 이메일 중복이 `409 Conflict`를 반환하는지 테스트한다.
- [x] 닉네임 중복이 `409 Conflict`를 반환하는지 테스트한다.
- [x] 전화번호 중복이 `409 Conflict`를 반환하는지 테스트한다.
- [x] 인증되지 않은 사용자도 회원가입 API에 접근할 수 있는지 테스트한다.
- [x] CSRF 토큰이 없으면 `403 Forbidden`을 반환하는지 테스트한다.
- [x] 유효한 CSRF 쿠키와 헤더가 있으면 Security 검사를 통과하는지 테스트한다.

---

## 11. DB 제약조건 검증

- [x] 애플리케이션 코드뿐 아니라 DB에도 이메일 `UNIQUE` 제약조건을 적용한다.
- [x] DB에도 닉네임 `UNIQUE` 제약조건을 적용한다.
- [x] DB에도 전화번호 `UNIQUE` 제약조건을 적용한다.
- [x] 동시에 동일한 이메일로 가입할 때 DB 제약조건이 중복 저장을 차단하는지 확인한다.
- [x] DB 제약조건 위반을 `409 Conflict`로 변환할 처리 방법을 검토한다.

애플리케이션의 `existsByEmail()` 검사와 DB의 `UNIQUE` 제약조건은 역할이 다릅니다.

```text
existsByEmail()       → 사용자에게 이해하기 쉬운 중복 오류를 빠르게 반환
DB UNIQUE constraint → 동시에 들어온 요청까지 포함해 중복 저장을 최종 차단
```

---

## 12. 로그 및 개인정보 점검

- [x] 평문 비밀번호를 로그에 출력하지 않는다.
- [x] 요청 DTO 전체를 그대로 로그에 출력하지 않는다.
- [x] 예외 로그에 비밀번호가 포함되지 않는지 확인한다.
- [x] 회원가입 응답에 비밀번호가 포함되지 않는지 확인한다.
- [x] Validation 오류 응답에 민감한 입력값이 포함되지 않는지 확인한다.
- [x] 암호화된 비밀번호도 불필요하게 외부에 노출하지 않는다.

---

## 13. Swagger/OpenAPI 문서화

- [x] 회원가입 API가 Swagger UI에 표시되는지 확인한다.
- [x] API의 목적과 성공 응답을 설명한다.
- [x] `SignupRequest` 각 필드의 의미와 검증 조건을 설명한다.
- [x] 비밀번호 예시가 실제 비밀번호처럼 보이지 않도록 작성한다.
- [x] `201 Created` 응답을 문서화한다.
- [x] `400 Bad Request` 응답을 문서화한다.
- [x] `403 Forbidden` 응답을 문서화한다.
- [x] `409 Conflict` 응답을 문서화한다.
- [x] Swagger UI에서 CSRF 토큰이 필요한 회원가입 요청을 어떻게 실행할지 확인한다.

Swagger UI 실행 순서:

1. `/swagger-ui/index.html`에 접속한다.
2. `GET /api/v1/auth/csrf`를 먼저 실행하여 `XSRF-TOKEN` 쿠키를 발급받는다.
3. `POST /api/v1/auth/signup`을 실행한다.
4. springdoc의 CSRF 지원이 쿠키 값을 `X-XSRF-TOKEN` 헤더에 자동으로 포함한다.

---

## 14. 최종 실행 검증

- [x] 애플리케이션이 정상적으로 실행된다.
- [x] `GET /api/v1/auth/csrf`로 CSRF 토큰을 발급받을 수 있다.
- [x] 발급된 `XSRF-TOKEN` 쿠키 값이 존재한다.
- [x] 회원가입 요청에 `X-XSRF-TOKEN` 헤더를 포함한다.
- [x] 정상 회원가입 요청이 `201 Created`를 반환한다.
- [x] DB에 사용자가 저장된다.
- [x] DB에 평문 비밀번호가 저장되지 않는다.
- [x] 저장된 권한이 `USER`이다.
- [x] 같은 이메일로 다시 가입하면 `409 Conflict`가 반환된다.
- [x] 같은 닉네임으로 다시 가입하면 `409 Conflict`가 반환된다.
- [x] 같은 전화번호로 다시 가입하면 `409 Conflict`가 반환된다.
- [x] 전체 테스트를 실행한다.

Windows:

```powershell
.\gradlew.bat test
```

macOS 또는 Linux:

```bash
./gradlew test
```

---

## 15. 회원가입 완료 기준

다음 조건을 모두 만족하면 회원가입 기능 구현이 완료된 것으로 판단합니다.

- [ ] `POST /api/v1/auth/signup`이 동작한다.
- [ ] 올바른 요청은 `201 Created`를 반환한다.
- [ ] 입력값 Validation이 적용된다.
- [ ] 이메일, 닉네임, 전화번호 중복을 차단한다.
- [ ] DB `UNIQUE` 제약조건으로 중복 저장을 최종 차단한다.
- [ ] 비밀번호는 BCrypt로 암호화되어 저장된다.
- [ ] 기본 권한은 서버에서 `USER`로 지정한다.
- [ ] 비밀번호가 응답과 로그에 노출되지 않는다.
- [ ] 예외 응답과 HTTP 상태 코드가 일관적이다.
- [ ] Security와 CSRF 설정을 유지한 상태에서 API가 동작한다.
- [ ] Service 및 Controller 테스트가 통과한다.
- [ ] Swagger/OpenAPI 문서에서 회원가입 API를 확인할 수 있다.

---

## 16. 권장 구현 순서

```text
1. User 엔티티와 DB 제약조건 점검
2. UserRepository 작성
3. SignupRequest 작성
4. SignupResponse 작성
5. 중복 예외 정의
6. UserService 회원가입 로직 작성
7. AuthController 작성
8. 공통 예외 처리 작성
9. Service 테스트
10. Controller 및 Security 통합 테스트
11. Swagger/OpenAPI 문서화
12. 전체 테스트와 실제 DB 저장 결과 확인
```
