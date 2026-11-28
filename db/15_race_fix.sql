-- Лаба 4. Гонки при продаже последнего места.
--
-- Проблема: проверка «есть ли место» и запись билета идут отдельными шагами.
-- Две сессии одновременно видят «свободно одно место», и обе его продают:
-- триггер tickets_check_capacity не видит незафиксированный билет соседней сессии.
--
-- Исправление: buy_ticket первым делом блокирует строку показа (SELECT ... FOR UPDATE).
-- Блокируем не tickets, а общую строку, за которую спорят обе сессии: сам показ.
-- Вторая сессия ждёт COMMIT первой; её следующий запрос (free_seats) уже видит проданное место.
-- Показы блокируются независимо: продажи на разные показы друг друга не ждут.
CREATE OR REPLACE FUNCTION buy_ticket(p_show integer, p_row integer, p_seat integer, p_buyer text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v_price  numeric(10,2);
    v_id     integer;
BEGIN
    -- очередь на показ: вторая транзакция ждёт здесь
    SELECT status, base_price INTO v_status, v_price
    FROM shows
    WHERE id = p_show
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Показ % не найден', p_show;
    END IF;
    IF v_status <> 'planned' THEN
        RAISE EXCEPTION 'Билеты на показ % не продаются (статус: %)', p_show, v_status;
    END IF;

    -- считаем после блокировки: видны уже зафиксированные билеты
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
