-- 전체 스키마 확인용 DDL
-- 1. members (회원)
CREATE TABLE members (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    nickname VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_members_role CHECK (role IN ('USER', 'ADMIN'))
);

-- 2. movies (영화)
CREATE TABLE movies (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    running_time_minutes INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_movies_running_time CHECK (running_time_minutes > 0)
);

-- 3. theaters (영화관)
CREATE TABLE theaters (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. auditoriums (상영관)
CREATE TABLE auditoriums (
    id BIGSERIAL PRIMARY KEY,
    theater_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    total_seats INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoriums_theater
        FOREIGN KEY (theater_id) REFERENCES theaters (id),
    CONSTRAINT uk_auditoriums_theater_name
        UNIQUE (theater_id, name),
    CONSTRAINT chk_auditoriums_total_seats CHECK (total_seats >= 0)
);

-- 5. seats (좌석)
CREATE TABLE seats (
    id BIGSERIAL PRIMARY KEY,
    auditorium_id BIGINT NOT NULL,
    row_name VARCHAR(10) NOT NULL,
    seat_number INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_seats_auditorium
        FOREIGN KEY (auditorium_id) REFERENCES auditoriums (id),
    CONSTRAINT uk_seats_auditorium_row_number
        UNIQUE (auditorium_id, row_name, seat_number),
    CONSTRAINT chk_seats_number CHECK (seat_number > 0)
);

-- 6. screenings (상영 일정)
CREATE TABLE screenings (
    id BIGSERIAL PRIMARY KEY,
    movie_id BIGINT NOT NULL,
    auditorium_id BIGINT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_screenings_movie
        FOREIGN KEY (movie_id) REFERENCES movies (id),
    CONSTRAINT fk_screenings_auditorium
        FOREIGN KEY (auditorium_id) REFERENCES auditoriums (id),
    CONSTRAINT chk_screenings_time CHECK (start_time < end_time),
    CONSTRAINT chk_screenings_status
        CHECK (status IN ('SCHEDULED', 'OPEN', 'CLOSED', 'CANCELED'))
);

-- 7. screening_seats (상영 좌석)
CREATE TABLE screening_seats (
    id BIGSERIAL PRIMARY KEY,
    screening_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    price BIGINT NOT NULL,
    hold_expires_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_screening_seats_screening
        FOREIGN KEY (screening_id) REFERENCES screenings (id),
    CONSTRAINT fk_screening_seats_seat
        FOREIGN KEY (seat_id) REFERENCES seats (id),
    CONSTRAINT uk_screening_seats_screening_seat
        UNIQUE (screening_id, seat_id),
    CONSTRAINT chk_screening_seats_status
        CHECK (status IN ('AVAILABLE', 'HOLD', 'RESERVED', 'UNAVAILABLE')),
    CONSTRAINT chk_screening_seats_price CHECK (price >= 0),
    CONSTRAINT chk_screening_seats_version CHECK (version >= 0)
);

-- 8. reservations (예매)
CREATE TABLE reservations (
    id BIGSERIAL PRIMARY KEY,
    reservation_number VARCHAR(50) UNIQUE NOT NULL,
    member_id BIGINT NOT NULL,
    screening_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount INT NOT NULL,
    expires_at TIMESTAMPTZ,
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reservations_member
        FOREIGN KEY (member_id) REFERENCES members (id),
    CONSTRAINT fk_reservations_screening
        FOREIGN KEY (screening_id) REFERENCES screenings (id),
    CONSTRAINT chk_reservations_status
        CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELED', 'EXPIRED')),
    CONSTRAINT chk_reservations_total_amount CHECK (total_amount >= 0)
);

-- 9. reservation_seats (예매 좌석)
CREATE TABLE reservation_seats (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL,
    screening_seat_id BIGINT NOT NULL,
    price INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reservation_seats_reservation
        FOREIGN KEY (reservation_id) REFERENCES reservations (id),
    CONSTRAINT fk_reservation_seats_screening_seat
        FOREIGN KEY (screening_seat_id) REFERENCES screening_seats (id),
    CONSTRAINT uk_reservation_seats_reservation_screening_seat
        UNIQUE (reservation_id, screening_seat_id),
    CONSTRAINT chk_reservation_seats_price CHECK (price >= 0)
);
