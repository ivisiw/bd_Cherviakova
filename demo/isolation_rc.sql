-- Лаба 4 ★. Неповторяющееся чтение на READ COMMITTED.
-- Окно A дважды читает цену показа, между чтениями окно B меняет её и фиксирует сразу (autocommit).
-- Запуск: dbcheck run demo/isolation_rc.sql

-- [setup] Тестовый показ с ценой 700
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (12, 3, '2027-01-10 19:00+03', '2027-01-10 21:00+03', 700.00);

-- [A] Первое чтение
-- expect: value 700
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT base_price::int FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [B] Меняет цену, фиксируется сразу
UPDATE shows SET base_price = 900.00 WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A] Второе чтение: новый снимок, видна цена из окна B
-- expect: value 900
SELECT base_price::int FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A]
COMMIT;

-- [cleanup]
DELETE FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
