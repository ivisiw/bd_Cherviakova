-- Лаба 3. Триггеры

-- ============================================================
-- 1. Правило темы: актёр не играет в двух показах одновременно.
-- Ограничение EXCLUDE из лабы 1 уже запрещает это, но отвечает технической ошибкой.
-- Триггер срабатывает раньше и называет актёра и показ. Код ошибки оставлен 23P01
-- (exclusion_violation), поэтому demo/lab1_bonus.sql (expect: error 23P01) работает как прежде.
-- ============================================================
CREATE OR REPLACE FUNCTION check_actor_free() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_other_show integer;
BEGIN
    SELECT c.show_id INTO v_other_show
    FROM casting c
    WHERE c.actor_id = NEW.actor_id
      AND NOT (c.show_id = NEW.show_id AND c.role_id = NEW.role_id)
      AND tstzrange(c.starts_at, c.ends_at) && tstzrange(NEW.starts_at, NEW.ends_at)
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION 'Актёр % уже играет в показе % в это время (пересекается с показом %)',
            NEW.actor_id, v_other_show, NEW.show_id
            USING ERRCODE = 'exclusion_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE OR REPLACE TRIGGER casting_check_actor_free
BEFORE INSERT OR UPDATE OF actor_id, starts_at, ends_at ON casting
FOR EACH ROW EXECUTE FUNCTION check_actor_free();

-- ============================================================
-- 2. Вместимость зала: на показ нельзя продать больше мест, чем в зале.
-- Эту проверку не выразить через CHECK или UNIQUE (нужно посчитать другие строки),
-- и она защищает от прямого INSERT в tickets в обход buy_ticket.
-- ============================================================
CREATE OR REPLACE FUNCTION check_show_capacity() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_capacity integer;
    v_taken    integer;
BEGIN
    IF NEW.status NOT IN ('sold', 'reserved') THEN
        RETURN NEW;                      -- возвращённый билет место не занимает
    END IF;

    SELECT h.capacity INTO v_capacity
    FROM shows s JOIN halls h ON h.id = s.hall_id
    WHERE s.id = NEW.show_id;

    IF v_capacity IS NULL THEN
        RETURN NEW;                      -- показа нет: пусть внешний ключ вернёт свою ошибку
    END IF;

    SELECT count(*) INTO v_taken
    FROM tickets t
    WHERE t.show_id = NEW.show_id
      AND t.status IN ('sold', 'reserved')
      AND t.id IS DISTINCT FROM NEW.id;  -- при UPDATE не считаем саму строку

    IF v_taken >= v_capacity THEN
        RAISE EXCEPTION 'На показ % нет мест (вместимость зала %)', NEW.show_id, v_capacity;
    END IF;
    RETURN NEW;
END $$;

CREATE OR REPLACE TRIGGER tickets_check_capacity
BEFORE INSERT OR UPDATE OF status, show_id ON tickets
FOR EACH ROW EXECUTE FUNCTION check_show_capacity();

-- ============================================================
-- 3. Служебный триггер: время последнего изменения показа
-- ============================================================
ALTER TABLE shows ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE OR REPLACE TRIGGER shows_updated_at
BEFORE UPDATE ON shows
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
