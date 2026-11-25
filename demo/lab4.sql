-- Лаба 4. Транзакции и доступ.
-- Запуск: dbcheck run demo/lab4.sql --sql

-- 1. Сумма цен билетов первого показа до транзакции
-- expect: rows 1
SELECT sum(price) AS total FROM tickets WHERE show_id = 1;

-- 2. Транзакция: цены растут на 500, затем вставка дубля места падает. Откатывается всё
-- expect: error unique
BEGIN;
UPDATE tickets SET price = price + 500 WHERE show_id = 1;
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
VALUES (1, 1, 1, 100.00, 'Дубль');
COMMIT;

-- 3. Данные не изменились: сумма прежняя
-- expect: same 1
SELECT sum(price) AS total FROM tickets WHERE show_id = 1;

-- 4. app_reader читает представление
-- expect: rows 14
RESET ROLE;
SET ROLE app_reader;
SELECT show_id, title, hall, free_seats FROM v_show_card;

-- 5. app_reader пользуется поиском показов
-- expect: rows 5
RESET ROLE;
SET ROLE app_reader;
SELECT * FROM find_shows(p_hall => 'Большая сцена');

-- 6. app_reader не читает таблицу напрямую
-- expect: error permission
RESET ROLE;
SET ROLE app_reader;
SELECT * FROM tickets;

-- 7. app_reader не меняет данные
-- expect: error permission
RESET ROLE;
SET ROLE app_reader;
UPDATE shows SET base_price = 0;

-- 8. app_reader не вызывает продажу билета
-- expect: error permission
RESET ROLE;
SET ROLE app_reader;
SELECT buy_ticket(1, 2, 7, 'Не должно сработать');

-- 9. app_writer не вставляет в таблицу напрямую
-- expect: error permission
RESET ROLE;
SET ROLE app_writer;
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name)
VALUES (1, 99, 1, 100.00, 'Прямой INSERT');

-- 10. app_writer не удаляет данные
-- expect: error permission
RESET ROLE;
SET ROLE app_writer;
DELETE FROM shows;

-- 11. app_writer вызывает бизнес-операцию (билет продан и откатывается: ничего не остаётся)
-- expect: rows 1
RESET ROLE;
BEGIN;
SET ROLE app_writer;
SELECT buy_ticket(1, 2, 7, 'Роль writer') AS ticket_id;
RESET ROLE;
ROLLBACK;

-- 12. app_writer читает то же, что reader (членство в роли)
-- expect: rows 14
RESET ROLE;
SET ROLE app_writer;
SELECT show_id, title FROM v_show_card;

-- 13. Возвращаемся к владельцу
RESET ROLE;
