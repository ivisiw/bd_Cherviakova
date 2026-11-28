-- Лаба 4 ★. Тот же сценарий на REPEATABLE READ: транзакция видит один снимок.
-- Запуск: dbcheck run demo/isolation_rr.sql

-- [setup] Тестовый показ с ценой 700
DELETE FROM tickets WHERE show_id IN (SELECT id FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03');
DELETE FROM shows  WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (12, 3, '2027-01-10 19:00+03', '2027-01-10 21:00+03', 700.00);

-- [A] Первое чтение: здесь берётся снимок на всю транзакцию
-- expect: value 700
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT base_price::int FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [B] Меняет цену, фиксируется сразу
UPDATE shows SET base_price = 900.00 WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A] Второе чтение: снимок прежний, цена всё ещё 700
-- expect: value 700
SELECT base_price::int FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A] Изменить строку, которую после снимка поменял другой: ошибка сериализации
-- expect: error 40001
UPDATE shows SET base_price = base_price + 1 WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';

-- [A]
ROLLBACK;

-- [cleanup]
DELETE FROM shows WHERE hall_id = 3 AND starts_at = '2027-01-10 19:00+03';
