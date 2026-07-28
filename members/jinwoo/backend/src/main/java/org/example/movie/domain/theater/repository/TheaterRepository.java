package org.example.movie.domain.theater.repository;

import org.example.movie.domain.theater.entity.Theater;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TheaterRepository extends JpaRepository<Theater,Long> {
}
