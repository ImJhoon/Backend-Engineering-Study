package org.example.movie.global.config;

import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.OpenAPI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {
    @Bean
    public OpenAPI movieOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("영화 예매 API")
                        .description("영화 예매 서비스 REST API 문서")
                        .version("v1")
                );
    }
}
