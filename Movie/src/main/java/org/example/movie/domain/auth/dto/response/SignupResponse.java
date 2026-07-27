package org.example.movie.domain.auth.dto.response;

import org.example.movie.domain.member.entity.Member;

public record SignupResponse(
        Long id,
        String email,
        String name
) {
    public static SignupResponse from(Member member) {
        return new SignupResponse(
                member.getId(),
                member.getEmail(),
                member.getNickname()
        );
    }
}
