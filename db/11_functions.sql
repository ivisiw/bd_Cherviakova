-- Лаба 3. Функции

-- 1. Свободные места на показ (возвращает число; для несуществующего показа NULL)
CREATE OR REPLACE FUNCTION free_seats(p_show integer)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT h.capacity - (SELECT count(*)
                         FROM tickets t
                         WHERE t.show_id = s.id
                           AND t.status IN ('sold', 'reserved'))::integer
    FROM shows s
    JOIN halls h ON h.id = s.hall_id
    WHERE s.id = p_show;
$$;

-- 2. Расписание актёра (возвращает таблицу)
CREATE OR REPLACE FUNCTION actor_schedule(p_actor integer)
RETURNS TABLE (show_id integer, title text, role text, starts_at timestamptz, ends_at timestamptz)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, p.title, r.name, s.starts_at, s.ends_at
    FROM casting c
    JOIN shows s ON s.id = c.show_id
    JOIN plays p ON p.id = s.play_id
    JOIN roles r ON r.id = c.role_id
    WHERE c.actor_id = p_actor
    ORDER BY s.starts_at;
$$;

-- 3. Бизнес-операция: продать билет одной командой, вернуть id билета.
-- Цена берётся из показа. Если место занято возвращённым билетом, то этот билет
-- перепродаётся (UNIQUE по месту не даёт вставить вторую строку).
CREATE OR REPLACE FUNCTION buy_ticket(p_show integer, p_row integer, p_seat integer, p_buyer text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v_price  numeric(10,2);
    v_id     integer;
BEGIN
    SELECT status, base_price INTO v_status, v_price
    FROM shows WHERE id = p_show;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Показ % не найден', p_show;
    END IF;
    IF v_status <> 'planned' THEN
        RAISE EXCEPTION 'Билеты на показ % не продаются (статус: %)', p_show, v_status;
    END IF;
    IF free_seats(p_show) <= 0 THEN
        RAISE EXCEPTION 'На показ % нет мест', p_show;
    END IF;

    INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name, status, sold_at)
    VALUES (p_show, p_row, p_seat, v_price, p_buyer, 'sold', now())
    ON CONFLICT (show_id, seat_row, seat_number) DO UPDATE
        SET price      = EXCLUDED.price,
            buyer_name = EXCLUDED.buyer_name,
            status     = 'sold',
            sold_at    = now()
        WHERE tickets.status = 'returned'
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Место (ряд %, номер %) на показ % уже занято', p_row, p_seat, p_show;
    END IF;

    RETURN v_id;
END $$;
