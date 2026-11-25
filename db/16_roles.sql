-- Лаба 4. Роли и права.
-- Пароли приходят из переменных окружения контейнера
-- Если переменные не заданы, скрипт упадёт: роль без пароля не создаём.
\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

-- app_reader: сайт, страница афиши. Только читает.
CREATE ROLE app_reader LOGIN PASSWORD :'reader_password';
-- app_writer: сайт, кнопка «Купить». Входит в app_reader и вызывает бизнес-операцию.
CREATE ROLE app_writer LOGIN PASSWORD :'writer_password' IN ROLE app_reader;

-- Забираем у всех возможность вызвать любую функцию, потом выдаём точечно.
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO app_reader;

-- Чтение: только представления
GRANT SELECT ON v_show_card, v_show_cast TO app_reader;
GRANT EXECUTE ON FUNCTION find_shows(text, text, timestamptz, timestamptz, numeric, boolean) TO app_reader;

-- SECURITY DEFINER: функция работает с правами владельца,
-- поэтому app_writer не нужны права на tickets, а проверки внутри функции обойти нельзя.
-- search_path фиксируем, чтобы нельзя было подменить объекты через чужую схему.
ALTER FUNCTION buy_ticket(integer, integer, integer, text)
    SECURITY DEFINER SET search_path = public, pg_temp;
GRANT EXECUTE ON FUNCTION buy_ticket(integer, integer, integer, text) TO app_writer;