-- Лаба 1. Схема БД «Театр»

-- нужно для EXCLUDE: сравнение «=» по обычным типам вместе с «&&» по диапазонам времени
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ---------- Справочник: залы ----------
CREATE TABLE halls (
    id        int  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      text NOT NULL UNIQUE,
    capacity  int  NOT NULL CHECK (capacity > 0)
);

-- ---------- Спектакли ----------
CREATE TABLE plays (
    id            int  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         text NOT NULL UNIQUE,
    author        text NOT NULL,
    duration_min  int  NOT NULL CHECK (duration_min BETWEEN 10 AND 400),
    age_limit     int  NOT NULL DEFAULT 0 CHECK (age_limit IN (0, 6, 12, 16, 18))
);

-- ---------- Актёры ----------
CREATE TABLE actors (
    id         int  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name  text NOT NULL,
    birth_date date NOT NULL CHECK (birth_date > DATE '1930-01-01'),
    email      text NOT NULL UNIQUE CHECK (email LIKE '%_@_%')
);

-- ---------- Роли (принадлежат спектаклю) ----------
CREATE TABLE roles (
    id       int     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    play_id  int     NOT NULL REFERENCES plays (id) ON DELETE CASCADE,
    name     text    NOT NULL,
    is_lead  boolean NOT NULL DEFAULT false,
    UNIQUE (play_id, name),
    UNIQUE (id, play_id)            -- нужен для составного внешнего ключа из casting
);

-- ---------- Показы ----------
CREATE TABLE shows (
    id          int           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    play_id     int           NOT NULL REFERENCES plays (id) ON DELETE RESTRICT,
    hall_id     int           NOT NULL REFERENCES halls (id) ON DELETE RESTRICT,
    starts_at   timestamptz   NOT NULL,
    ends_at     timestamptz   NOT NULL,
    base_price  numeric(10,2) NOT NULL CHECK (base_price >= 0),
    status      text          NOT NULL DEFAULT 'planned'
                CHECK (status IN ('planned', 'done', 'cancelled')),
    CHECK (ends_at > starts_at),
    UNIQUE (id, play_id, starts_at, ends_at),   -- для составного внешнего ключа из casting
    -- в одном зале два показа не могут идти одновременно
    EXCLUDE USING gist (hall_id WITH =, tstzrange(starts_at, ends_at) WITH &&)
        WHERE (status <> 'cancelled')
);

-- актёр — роль ----------
CREATE TABLE casting (
    actor_id   int         NOT NULL REFERENCES actors (id) ON DELETE RESTRICT,
    role_id    int         NOT NULL REFERENCES roles  (id) ON DELETE RESTRICT,
    show_id    int         NOT NULL REFERENCES shows  (id) ON DELETE CASCADE,
    play_id    int         NOT NULL,
    starts_at  timestamptz NOT NULL,
    ends_at    timestamptz NOT NULL,
    PRIMARY KEY (actor_id, role_id, show_id),
    -- показ существует, и время/спектакль совпадают с ним
    FOREIGN KEY (show_id, play_id, starts_at, ends_at)
        REFERENCES shows (id, play_id, starts_at, ends_at)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- роль относится к тому же спектаклю, что и показ
    FOREIGN KEY (role_id, play_id)
        REFERENCES roles (id, play_id) ON DELETE RESTRICT,
    -- одну роль в показе играет один актёр
    UNIQUE (show_id, role_id),
    -- БИЗНЕС-ПРАВИЛО: актёр не играет в двух показах одновременно
    EXCLUDE USING gist (actor_id WITH =, tstzrange(starts_at, ends_at) WITH &&)
);

-- ---------- Билеты ----------
CREATE TABLE tickets (
    id           int           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    show_id      int           NOT NULL REFERENCES shows (id) ON DELETE RESTRICT,
    seat_row     int           NOT NULL CHECK (seat_row > 0),
    seat_number  int           NOT NULL CHECK (seat_number > 0),
    price        numeric(10,2) NOT NULL CHECK (price >= 0),
    buyer_name   text          NOT NULL,
    status       text          NOT NULL DEFAULT 'sold'
                 CHECK (status IN ('sold', 'reserved', 'returned')),
    sold_at      timestamptz   NOT NULL DEFAULT now(),
    UNIQUE (show_id, seat_row, seat_number)     -- одно место на показ — один билет
);
