-- Лаба 4. Та же гонка, но через исправленную операцию buy_ticket (блокировка показа FOR UPDATE).
-- Запуск: dbcheck run demo/race_fixed.sql

-- [setup] Тот же показ: 80 мест, свободно одно
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (12, 3, '2027-01-10 19:00+03', '2027-01-10 21:00+03', 700.00);
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
SELECT s.id, (n - 1) / 10 + 1, (n - 1) % 10 + 1, 700.00, 'Занято'
FROM shows s CROSS JOIN generate_series(1, 79) AS n
WHERE s.hall_id = 3 AND s.starts_at = '2027-01-10 19:00+03';

-- [A] Окно A: buy_ticket блокирует показ и продаёт последнее место
BEGIN;
SELECT buy_ticket(id, 8, 10, 'Окно A') FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [B] Окно B: ждёт блокировку показа, пока A не завершит транзакцию
-- expect: blocked
-- expect: error "нет мест"
BEGIN;
SELECT buy_ticket(id, 9, 1, 'Окно B') FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A]
COMMIT;

-- [B] Окно B дождалось, увидело проданное место и получило ошибку; откатываем
ROLLBACK;

-- [check] Продано не больше, чем мест в зале? 80 из 80: правило соблюдено
-- expect: true
SELECT count(*) FILTER (WHERE t.status IN ('sold', 'reserved')) <= (SELECT capacity FROM halls WHERE id = 3)
FROM tickets t JOIN shows s ON s.id = t.show_id
WHERE s.hall_id = 3 AND s.starts_at = '2027-01-10 19:00+03';

-- [cleanup]
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';