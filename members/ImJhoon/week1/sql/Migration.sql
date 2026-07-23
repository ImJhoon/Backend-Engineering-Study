-- 1. 기존 TIMESTAMP 컬럼들을 TIMESTAMPTZ로 타입 변경
ALTER TABLE users ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
ALTER TABLE screenings ALTER COLUMN start_time TYPE TIMESTAMPTZ USING start_time AT TIME ZONE 'UTC';
ALTER TABLE screenings ALTER COLUMN end_time TYPE TIMESTAMPTZ USING end_time AT TIME ZONE 'UTC';
ALTER TABLE reservations ALTER COLUMN reserved_at TYPE TIMESTAMPTZ USING reserved_at AT TIME ZONE 'UTC';
ALTER TABLE reservations ALTER COLUMN expires_at TYPE TIMESTAMPTZ USING expires_at AT TIME ZONE 'UTC';
ALTER TABLE payments ALTER COLUMN paid_at TYPE TIMESTAMPTZ USING paid_at AT TIME ZONE 'UTC';

-- 2. 상태 변경 추적을 위한 updated_at 컬럼 추가
ALTER TABLE users ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE screening_seats ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE reservations ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE payments ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 3. 데이터 무결성을 위한 CHECK 제약 조건 추가
ALTER TABLE users ADD CONSTRAINT chk_users_role CHECK (role IN ('USER', 'ADMIN'));
ALTER TABLE movies ADD CONSTRAINT chk_movies_running_time CHECK (running_time > 0);
ALTER TABLE theaters ADD CONSTRAINT chk_theaters_seat_count CHECK (total_seat_count > 0);
ALTER TABLE screenings ADD CONSTRAINT chk_screenings_time CHECK (end_time > start_time);
ALTER TABLE screenings ADD CONSTRAINT chk_screenings_price CHECK (base_price >= 0);
ALTER TABLE screening_seats ADD CONSTRAINT chk_screening_seats_status CHECK (status IN ('AVAILABLE', 'HOLD', 'RESERVED'));
ALTER TABLE reservations ADD CONSTRAINT chk_reservations_status CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED'));
ALTER TABLE reservation_seats ADD CONSTRAINT chk_reservation_seats_price CHECK (price_snapshot >= 0);
ALTER TABLE reservation_seats ADD CONSTRAINT chk_reservation_seats_cancel CHECK (cancel_status IN ('NONE', 'CANCELLED'));
ALTER TABLE payments ADD CONSTRAINT chk_payments_amount CHECK (amount >= 0);
ALTER TABLE payments ADD CONSTRAINT chk_payments_status CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'));

-- 4. 성능 최적화를 위한 인덱스 생성
CREATE INDEX idx_screenings_movie ON screenings(movie_id);
CREATE INDEX idx_screenings_theater_start ON screenings(theater_id, start_time);
CREATE INDEX idx_reservations_user ON reservations(user_id);
CREATE INDEX idx_reservation_seats_reservation ON reservation_seats(reservation_id);
CREATE INDEX idx_reservation_seats_screening_seat ON reservation_seats(screening_seat_id);
