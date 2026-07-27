package org.example.movie.domain.movie.dto.response;

import org.example.movie.domain.movie.entity.Movie;

public record MovieResponse (
        Long id,
        String title,
        Integer runningTimeMinutes
){
    public static MovieResponse from(Movie movie) {
        return new MovieResponse(
                movie.getId(),
                movie.getTitle(),
                movie.getRunningTimeMinutes()
        );
    }
}

