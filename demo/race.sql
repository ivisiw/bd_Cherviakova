-- Лаба 4. Гонка: продажа последнего места на показ из двух окон.
-- Прямой INSERT в tickets: триггер вместимости не видит незафиксированный билет другого окна.
-- Запуск: dbcheck run demo/race.sql

-- [setup] Показ в Малой сцене (80 мест), на котором свободно одно место
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (12, 3, '2027-01-10 19:00+03', '2027-01-10 21:00+03', 700.00);
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
SELECT s.id, (n - 1) / 10 + 1, (n - 1) % 10 + 1, 700.00, 'Занято'
FROM shows s CROSS JOIN generate_series(1, 79) AS n
WHERE s.hall_id = 3 AND s.starts_at = '2027-01-10 19:00+03';

-- [A] Окно A: свободно одно место, продаём ряд 8, место 10
BEGIN;
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
SELECT id, 8, 10, 700.00, 'Окно A' FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [B] Окно B в тот же момент: билет окна A не зафиксирован, триггер видит 79 мест и пропускает
BEGIN;
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
SELECT id, 9, 1, 700.00, 'Окно B' FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check] Продано не больше, чем мест в зале? В зале 80 мест, продано 81: правило нарушено
-- expect: false
SELECT count(*) FILTER (WHERE t.status IN ('sold', 'reserved')) <= (SELECT capacity FROM halls WHERE id = 3)
FROM tickets t JOIN shows s ON s.id = t.show_id
WHERE s.hall_id = 3 AND s.starts_at = '2027-01-10 19:00+03';

-- [cleanup]
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
