package org.example.movie.domain.member.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.movie.global.entity.BaseEntity;

@Getter
@Entity
@Table(name = "members")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Member extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true,  length = 250)
    private String email;
    @Column(nullable = false,  length = 250)
    private String password;
    @Column(nullable = false,  length = 250)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false,  length = 250)
    private MemberRole role;
}
