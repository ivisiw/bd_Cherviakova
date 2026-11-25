-- Лаба 4 ★★. Row Level Security: покупатель видит только свои билеты.
--
-- Идея: таблица одна на всех, но SELECT каждому возвращает только строки,
-- подходящие под политику. Условие добавляет сама база.
-- Кто «текущий покупатель», приложение сообщает после входа: SET app.buyer = 'Смирнов А.';

CREATE ROLE app_customer NOLOGIN;

GRANT USAGE ON SCHEMA public TO app_customer;
GRANT SELECT ON tickets TO app_customer;      -- только чтение; INSERT, UPDATE, DELETE прав нет

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Покупатель видит строки, где buyer_name совпадает с app.buyer.
-- current_setting('app.buyer', true): второй аргумент true не даёт ошибки, если параметр не задан;
-- тогда результат NULL, сравнение не истинно, и не видно ни одной строки.
CREATE POLICY own_tickets ON tickets
    FOR SELECT
    TO app_customer
    USING (buyer_name = current_setting('app.buyer', true));
