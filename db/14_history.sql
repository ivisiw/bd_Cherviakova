-- Лаба 3 ★★. Журнал изменений показов

CREATE TABLE IF NOT EXISTS shows_history (
    id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    show_id     integer     NOT NULL,          -- без внешнего ключа: журнал переживает удаление показа
    operation   text        NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_row     jsonb,
    new_row     jsonb,
    changed_by  text        NOT NULL DEFAULT session_user,
    changed_at  timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX IF NOT EXISTS shows_history_show_idx ON shows_history (show_id, changed_at);

CREATE OR REPLACE FUNCTION log_show_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO shows_history (show_id, operation, old_row, new_row)
    VALUES (coalesce(NEW.id, OLD.id), TG_OP, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NULL;                               -- результат AFTER-триггера не используется
END $$;

-- Исходное состояние показов (данные из 02_seed.sql появились до триггера)
INSERT INTO shows_history (show_id, operation, old_row, new_row, changed_by)
SELECT s.id, 'INSERT', NULL, to_jsonb(s), 'init'
FROM shows s
WHERE NOT EXISTS (SELECT 1 FROM shows_history h WHERE h.show_id = s.id);

CREATE OR REPLACE TRIGGER shows_log_change
AFTER INSERT OR UPDATE OR DELETE ON shows
FOR EACH ROW EXECUTE FUNCTION log_show_change();

-- Какой была запись о показе в заданный момент (NULL, если показа ещё не было или он удалён)
CREATE OR REPLACE FUNCTION show_state_at(p_show integer, p_at timestamptz)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
    SELECT CASE WHEN h.operation = 'DELETE' THEN NULL ELSE h.new_row END
    FROM shows_history h
    WHERE h.show_id = p_show
      AND h.changed_at <= p_at
    ORDER BY h.changed_at DESC, h.id DESC
    LIMIT 1;
$$;
