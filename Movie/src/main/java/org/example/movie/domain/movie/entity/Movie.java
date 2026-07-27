package org.example.movie.domain.movie.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.movie.global.entity.BaseEntity;

@Getter
@Entity
@Table(name="movies")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Movie extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false,  length = 250)
    private String title;
    @Column(name="running_time_minutes", nullable = false)
    private Integer runningTimeMinutes;

    public static Movie create(String title, Integer runningTimeMinutes) {
        Movie movie = new Movie();
        movie.title = title;
        movie.runningTimeMinutes = runningTimeMinutes;
        return movie;
    }
}

