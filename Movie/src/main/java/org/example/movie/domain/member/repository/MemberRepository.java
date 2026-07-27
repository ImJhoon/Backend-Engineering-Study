package org.example.movie.domain.member.repository;

import org.example.movie.domain.member.entity.Member;
import org.example.movie.domain.movie.entity.Movie;
import org.example.movie.global.entity.BaseEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRepository extends JpaRepository<Member, Long> {
}
