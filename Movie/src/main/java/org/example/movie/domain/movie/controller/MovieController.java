package org.example.movie.domain.movie.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.example.movie.domain.movie.dto.response.MovieResponse;
import org.example.movie.domain.movie.service.MovieService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Movie", description = "영화 조회 API")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/movies")
public class MovieController {
    private final MovieService movieService;

    @Operation(
            summary = "영화 목록 조회",
            description = "등록된 전체 영화 목록을 조회 합니다."
    )
    @GetMapping
    public ResponseEntity<List<MovieResponse>> findAll() {
        List<MovieResponse> responses = movieService.findAll();
        return ResponseEntity.ok(responses);
    }

    @Operation(
            summary = "영화 상세 조회",
            description = "영화 ID를 이용해 영화 상세 정보를 조회합니다."
    )
    @GetMapping("/{movieId}")
    public ResponseEntity<MovieResponse> findById(@PathVariable Long movieId) {
        MovieResponse response = movieService.findById(movieId);
        return ResponseEntity.ok(response);
    }
}
