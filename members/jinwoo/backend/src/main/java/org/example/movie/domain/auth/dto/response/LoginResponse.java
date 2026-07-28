package org.example.movie.domain.auth.dto.response;

import org.example.movie.domain.member.entity.Member;

public record LoginResponse(
        Long id,
        String email,
        String nickname
) {
    public static LoginResponse from(Member member) {
        return new LoginResponse(
                member.getId(),
                member.getEmail(),
                member.getNickname()
        );
    }
}
