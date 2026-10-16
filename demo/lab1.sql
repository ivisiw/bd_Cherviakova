-- Лаба 1. Три вставки, которые база данных обязана отклонить.
-- Формат описан в docs/scenarios.md.
-- Запуск: dbcheck run demo/lab1.sql

-- 1. Актёр с таким email уже есть: ошибка UNIQUE
-- expect: error unique
INSERT INTO actors (full_name, birth_date, email)
VALUES ('Test Actor', '1990-01-01', 'orlov@theatre.test');

-- 2. Отрицательная цена билета: ошибка CHECK
-- expect: error check
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
VALUES (1, 99, 1, -100.00, 'Test Buyer');

-- 3. Показ несуществующего спектакля (play_id = 999): ошибка внешнего ключа
-- expect: error fk
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (999, 1, '2027-01-10 19:00+03', '2027-01-10 21:30+03', 1000.00);
