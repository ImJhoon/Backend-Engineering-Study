package org.example.movie.domain.movie.repositiry;

import org.example.movie.domain.movie.entity.Movie;
import org.example.movie.global.entity.BaseEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MovieRepository extends JpaRepository<Movie, Long> {
}
