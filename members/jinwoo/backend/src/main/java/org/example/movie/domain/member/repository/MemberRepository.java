package org.example.movie.domain.member.repository;

import org.example.movie.domain.member.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MemberRepository extends JpaRepository<Member, Long> {

    boolean existsByEmail(String email); // 이메일 존재 확인

    Optional<Member> findByEmail(String email); //해당 이메일 조회
}
