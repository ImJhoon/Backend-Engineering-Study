-- 1. users (사용자)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. movies (영화)
CREATE TABLE movies (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    running_time INT NOT NULL,
    rating VARCHAR(20) NOT NULL,
    release_date DATE NOT NULL,
    genre VARCHAR(100),
    director VARCHAR(100),
    "cast" VARCHAR(255),
    plot TEXT,
    poster_url VARCHAR(255)
);

-- 3. cinemas (지점)
CREATE TABLE cinemas (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20)
);

-- 4. theaters (상영관)
CREATE TABLE theaters (
    id BIGSERIAL PRIMARY KEY,
    cinema_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    theater_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    total_seat_count INT NOT NULL,
    CONSTRAINT fk_theaters_cinema FOREIGN KEY (cinema_id) REFERENCES cinemas (id),
    CONSTRAINT uk_theaters_cinema_name UNIQUE (cinema_id, name)
);

-- 5. seats (좌석)
CREATE TABLE seats (
    id BIGSERIAL PRIMARY KEY,
    theater_id BIGINT NOT NULL,
    seat_row VARCHAR(10) NOT NULL,
    seat_number INT NOT NULL,
    seat_grade VARCHAR(20) NOT NULL,
    CONSTRAINT fk_seats_theater FOREIGN KEY (theater_id) REFERENCES theaters (id),
    CONSTRAINT uk_seats_theater_row_number UNIQUE (theater_id, seat_row, seat_number)
);

-- 6. screenings (상영 일정)
CREATE TABLE screenings (
    id BIGSERIAL PRIMARY KEY,
    movie_id BIGINT NOT NULL,
    theater_id BIGINT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    base_price INT NOT NULL,
    CONSTRAINT fk_screenings_movie FOREIGN KEY (movie_id) REFERENCES movies (id),
    CONSTRAINT fk_screenings_theater FOREIGN KEY (theater_id) REFERENCES theaters (id)
);

-- 7. screening_seats (상영 좌석)
CREATE TABLE screening_seats (
    id BIGSERIAL PRIMARY KEY,
    screening_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT fk_screening_seats_screening FOREIGN KEY (screening_id) REFERENCES screenings (id),
    CONSTRAINT fk_screening_seats_seat FOREIGN KEY (seat_id) REFERENCES seats (id),
    CONSTRAINT uk_screening_seats_screening_seat UNIQUE (screening_id, seat_id)
);

-- 8. reservations (예약)
CREATE TABLE reservations (
    id BIGSERIAL PRIMARY KEY,
    reservation_number VARCHAR(50) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    screening_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reserved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    CONSTRAINT fk_reservations_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_reservations_screening FOREIGN KEY (screening_id) REFERENCES screenings (id)
);

-- 9. reservation_seats (예약 상세)
CREATE TABLE reservation_seats (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL,
    screening_seat_id BIGINT NOT NULL,
    seat_grade_snapshot VARCHAR(20) NOT NULL,
    price_snapshot INT NOT NULL,
    cancel_status VARCHAR(20) NOT NULL DEFAULT 'NONE',
    CONSTRAINT fk_reservation_seats_reservation FOREIGN KEY (reservation_id) REFERENCES reservations (id),
    CONSTRAINT fk_reservation_seats_screening_seat FOREIGN KEY (screening_seat_id) REFERENCES screening_seats (id)
);

-- 10. payments (결제)
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    payment_key VARCHAR(50) UNIQUE NOT NULL,
    reservation_id BIGINT UNIQUE NOT NULL,
    amount INT NOT NULL,
    method VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMP,
    CONSTRAINT fk_payments_reservation FOREIGN KEY (reservation_id) REFERENCES reservations (id)
);
