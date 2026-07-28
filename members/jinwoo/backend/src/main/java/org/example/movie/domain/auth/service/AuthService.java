package org.example.movie.domain.auth.service;

import lombok.RequiredArgsConstructor;
import org.example.movie.domain.auth.dto.request.LoginRequest;
import org.example.movie.domain.auth.dto.request.SignupRequest;
import org.example.movie.domain.auth.dto.response.LoginResponse;
import org.example.movie.domain.auth.dto.response.SignupResponse;
import org.example.movie.domain.member.entity.Member;
import org.example.movie.domain.member.repository.MemberRepository;
import org.example.movie.global.security.CustomUserDetails;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public SignupResponse signup(SignupRequest request) {

        if (memberRepository.existsByEmail(request.email())){
            throw new IllegalArgumentException("이미 사용중인 이메일입니다.");
        }

        String encodedPassword = passwordEncoder.encode(request.password());

        Member member = Member.create(
                request.email(),
                encodedPassword,
                request.nickName()
        );

        Member savedMember = memberRepository.save(member);
        return SignupResponse.from(savedMember);
    }

    @Transactional
    public LoginResponse login(LoginRequest request) {
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                request.email(),
                request.password());

        Authentication authenticate = authenticationManager.authenticate(authentication);

        CustomUserDetails userDetails = (CustomUserDetails) authenticate.getPrincipal();

        Member member = userDetails.getMember();

        return LoginResponse.from(member);
    }
}
