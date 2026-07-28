package org.example.movie.domain.theater.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.movie.global.entity.BaseEntity;

@Getter
@Entity
@Table(name = "theaters")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Theater extends BaseEntity {
    @Id
    @GeneratedValue(strategy =  GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;
}
