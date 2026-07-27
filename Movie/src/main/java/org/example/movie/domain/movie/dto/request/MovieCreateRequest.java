package org.example.movie.domain.movie.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record MovieCreateRequest(
        @NotBlank
        String title,

        @Positive
        Integer runningTimeMinutes
) {
}
