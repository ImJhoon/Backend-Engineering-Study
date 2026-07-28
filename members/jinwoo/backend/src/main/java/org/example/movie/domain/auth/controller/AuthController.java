package org.example.movie.domain.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.movie.domain.auth.dto.request.LoginRequest;
import org.example.movie.domain.auth.dto.request.SignupRequest;
import org.example.movie.domain.auth.dto.response.LoginResponse;
import org.example.movie.domain.auth.dto.response.SignupResponse;
import org.example.movie.domain.auth.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth", description = "인증 API")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService authService;

    @Operation(summary = "회원가입")
    @PostMapping("/signup")
    public ResponseEntity<SignupResponse> signup(
            @Valid @RequestBody SignupRequest request
    ) {
        SignupResponse response = authService.signup(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @Operation(summary = "로그인")
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request,
            HttpSession session
    ){
        LoginResponse response = authService.login(request);
        session.setAttribute("LOGIN_MEMBER_ID", response.id());
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "로그인 여부 확인")
    @GetMapping("/me")
    public ResponseEntity<Long> me(HttpSession session){
        Long memberId = (Long) session.getAttribute("LOGIN_MEMBER_ID");

        if(memberId == null){
            throw new IllegalArgumentException("로그인이 필요합니다");
        }

        return ResponseEntity.ok(memberId);
    }

    @Operation(summary = "로그아웃")
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpSession session){
        session.invalidate();
        return ResponseEntity.noContent().build();
    }
}
