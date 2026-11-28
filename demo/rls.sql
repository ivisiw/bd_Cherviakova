-- Лаба 4 ★★. Row Level Security на tickets: покупатель видит только свои билеты.
-- Запуск: dbcheck run demo/rls.sql --sql

-- 1. Покупатель не назвал себя (app.buyer не задан): не видно ни одного билета
-- expect: value 0
RESET ROLE;
SET ROLE app_customer;
SELECT count(*) AS n FROM tickets;

-- 2. Покупатель «Смирнов А.» входит на сайт: приложение сообщает его имя, считаем видимые билеты
-- expect: rows 1
RESET ROLE;
SET ROLE app_customer;
SET app.buyer = 'Смирнов А.';
SELECT count(*) AS n FROM tickets;

-- 3. Все видимые строки принадлежат ему
-- expect: true
SELECT bool_and(buyer_name = 'Смирнов А.') FROM tickets;

-- 4. Владелец видит все билеты, но если отфильтровать по этому имени, число то же, что в шаге 2
-- expect: same 2
RESET ROLE;
SELECT count(*) AS n FROM tickets WHERE buyer_name = 'Смирнов А.';

-- 5. Другой покупатель не видит чужих билетов: чужих строк 0
-- expect: value 0
SET ROLE app_customer;
SET app.buyer = 'Попов Д.';
SELECT count(*) FILTER (WHERE buyer_name <> 'Попов Д.') AS foreign_rows FROM tickets;

-- 6. Покупатель не может менять билеты
-- expect: error permission
UPDATE tickets SET price = 0;

-- 7. Возвращаемся к владельцу
RESET ROLE;
RESET app.buyer;
