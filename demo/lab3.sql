-- Лаба 3. Логика в базе «Театр»: представления, функции, триггеры.
-- Файл без BEGIN/COMMIT: чекер выполняет его в одной транзакции и откатывает в конце.
-- Запуск: dbcheck run demo/lab3.sql --sql

-- ============================================================
-- Представления
-- ============================================================

-- 1. Карточки показов: афиша с залом, ценой и занятостью
-- expect: rows 14
SELECT show_id, title, hall, starts_at, base_price, capacity, taken, free_seats
FROM v_show_card
ORDER BY starts_at;

-- 2. Первый показ: 300 мест в зале, 76 занято (возвращённые билеты место не занимают)
-- expect: value 224
SELECT free_seats FROM v_show_card WHERE show_id = 1;

-- 3. Состав показов: 42 строки распределения ролей
-- expect: rows 42
SELECT title, starts_at, role, actor
FROM v_show_cast
ORDER BY show_id, is_lead DESC, role;

-- ============================================================
-- Функции
-- ============================================================

-- 4. free_seats: свободные места на первый показ
-- expect: value 224
SELECT free_seats(1);

-- 5. actor_schedule: Иван Орлов занят в четырёх показах
-- expect: rows 4
SELECT * FROM actor_schedule(1);

-- ============================================================
-- Бизнес-операция buy_ticket
-- ============================================================

-- 6. Место 7 в ряду 2 первого показа сдано (returned): продаём его заново
-- expect: rows 1
SELECT buy_ticket(1, 2, 7, 'Анна Тестова') AS ticket_id;

-- 7. Результат в таблице: билет снова sold и принадлежит Анне
-- expect: true
SELECT status = 'sold' AND buyer_name = 'Анна Тестова'
FROM tickets
WHERE show_id = 1 AND seat_row = 2 AND seat_number = 7;

-- 8. Свободных мест стало на одно меньше
-- expect: value 223
SELECT free_seats(1);

-- 9. Место 1 в ряду 1 уже продано: ошибка функции
-- expect: error "уже занято"
SELECT buy_ticket(1, 1, 1, 'Дубль');

-- ============================================================
-- Триггер вместимости зала (tickets_check_capacity)
-- ============================================================

-- 10. Малая сцена, 80 мест, 76 занято. Продаём четыре возвращённых места третьего показа
-- expect: rows 4
SELECT buy_ticket(t.show_id, t.seat_row, t.seat_number, 'Тест Покупатель') AS ticket_id
FROM tickets t
WHERE t.show_id = 3 AND t.status = 'returned'
ORDER BY t.id;

-- 11. Зал заполнен
-- expect: value 0
SELECT free_seats(3);

-- 12. buy_ticket отказывает: мест нет
-- expect: error "нет мест"
SELECT buy_ticket(3, 9, 1, 'Лишний');

-- 13. Прямой INSERT в обход функции: отказывает триггер
-- expect: error "нет мест"
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
VALUES (3, 9, 2, 500.00, 'Прямой INSERT');

-- ============================================================
-- Правило темы: актёр не играет в двух показах одновременно
-- ============================================================

-- 14. В Камерном зале появляется показ «Маленького принца» 5 ноября с 20:00
-- expect: rows 1
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (11, 2, '2026-11-05 20:00+03', '2026-11-05 21:30+03', 500.00);

-- 15. Иван Орлов в это время играет в первом показе (19:00-21:30): триггер casting_check_actor_free
-- expect: error "уже играет"
INSERT INTO casting (actor_id, role_id, show_id, play_id, starts_at, ends_at)
SELECT 1, 31, id, play_id, starts_at, ends_at
FROM shows WHERE hall_id = 2 AND starts_at = '2026-11-05 20:00+03';

-- ============================================================
-- Служебный триггер updated_at
-- ============================================================

-- 16. Меняем цену первого показа
-- expect: rows 1
UPDATE shows SET base_price = base_price + 100 WHERE id = 1;

-- 17. updated_at проставился сам (now() в одной транзакции совпадает со временем триггера)
-- expect: true
SELECT updated_at = now() FROM shows WHERE id = 1;

-- ============================================================
-- ★★ Журнал изменений shows_history
-- ============================================================

-- 18. В журнале одна запись UPDATE по первому показу
-- expect: value 1
SELECT count(*) FROM shows_history WHERE show_id = 1 AND operation = 'UPDATE';

-- 19. Старая и новая цена в журнале, кто и когда изменил
-- expect: rows 1
SELECT old_row->>'base_price' AS old_price, new_row->>'base_price' AS new_price,
       changed_by, changed_at
FROM shows_history
WHERE show_id = 1 AND operation = 'UPDATE';

-- 20. Состояние показа сейчас: цена 1600.00
-- expect: true
SELECT show_state_at(1, clock_timestamp())->>'base_price' = '1600.00';

-- 21. Состояние показа за мгновение до изменения: цена была 1500.00
-- expect: true
SELECT show_state_at(1, (SELECT changed_at FROM shows_history
                         WHERE show_id = 1 AND operation = 'UPDATE') - interval '1 microsecond')
       ->> 'base_price' = '1500.00';

-- ============================================================
-- ★ Поиск и материализованное представление
-- ============================================================

-- 22. find_shows: показы Большой сцены (остальные фильтры не переданы)
-- expect: rows 5
SELECT * FROM find_shows(p_hall => 'Большая сцена');

-- 23. find_shows: «Ревизор» (регистр не важен)
-- expect: rows 2
SELECT * FROM find_shows(p_title => 'ревизор');

-- 24. find_shows: Малая сцена, только со свободными местами (третий показ заполнен в шаге 10)
-- expect: rows 3
SELECT * FROM find_shows(p_hall => 'Малая сцена', p_only_free => true);

-- 25. Выручка по месяцам из снимка
-- expect: rows >= 1
SELECT month, tickets_sold, revenue FROM mv_monthly_revenue ORDER BY month;

-- 26. Общая выручка в снимке до изменений
-- expect: rows 1
SELECT sum(revenue) AS total_before FROM mv_monthly_revenue;

-- 27. Билет подорожал на 1000
-- expect: rows 1
UPDATE tickets SET price = price + 1000
WHERE show_id = 1 AND seat_row = 1 AND seat_number = 1;

-- 28. Снимок не изменился: данные в нём старые
-- expect: same 26
SELECT sum(revenue) AS total_still_old FROM mv_monthly_revenue;

-- 29. Обновляем снимок
-- expect: ok
REFRESH MATERIALIZED VIEW mv_monthly_revenue;

-- 30. После REFRESH снимок совпадает с таблицей билетов
-- expect: true
SELECT (SELECT sum(revenue) FROM mv_monthly_revenue)
     = (SELECT sum(price) FROM tickets WHERE status = 'sold');
