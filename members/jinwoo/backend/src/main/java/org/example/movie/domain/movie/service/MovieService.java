package org.example.movie.domain.movie.service;

import lombok.RequiredArgsConstructor;
import org.example.movie.domain.movie.dto.request.MovieCreateRequest;
import org.example.movie.domain.movie.dto.response.MovieResponse;
import org.example.movie.domain.movie.entity.Movie;
import org.example.movie.domain.movie.repositiry.MovieRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MovieService {
    private final MovieRepository movieRepository;

    public List<MovieResponse> findAll() {
        return movieRepository.findAll()
                .stream()
                .map(MovieResponse::from)
                .toList();
    }

    public MovieResponse findById(Long movieId) {
        Movie movie = movieRepository.findById(movieId)
                .orElseThrow(() -> new IllegalArgumentException("영화를 찾을 수 없습니다. movieId=" + movieId));
        return MovieResponse.from(movie);
    }
}
