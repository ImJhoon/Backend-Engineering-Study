package org.example.movie.domain.auth.service;

import lombok.RequiredArgsConstructor;
import org.example.movie.domain.auth.dto.request.LoginRequest;
import org.example.movie.domain.auth.dto.request.SignupRequest;
import org.example.movie.domain.auth.dto.response.LoginResponse;
import org.example.movie.domain.auth.dto.response.SignupResponse;
import org.example.movie.domain.member.entity.Member;
import org.example.movie.domain.member.repository.MemberRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;

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
        Member member = memberRepository.findByEmail(request.email())
                .orElseThrow(()->
                        new IllegalArgumentException("이메일 또는 비밀번호가 올바르지 않습니다."));

        boolean matches = passwordEncoder.matches(
                request.password(),
                member.getPassword()
        );

        if(!matches){
            throw new IllegalArgumentException("이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        return LoginResponse.from(member);
    }
}
