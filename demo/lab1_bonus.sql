-- Бизнес-правило «актёр не играет в двух показах одновременно».
-- Актёр 1 в показе 1 играет 5 ноября с 19:00 до 21:30 (+03).
-- Создаём в другом зале показ на 20:00 и пробуем поставить того же актёра.
BEGIN;

INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
VALUES (11, 2, '2026-11-05 20:00+03', '2026-11-05 21:30+03', 500.00);

-- 1. Актёр 1 уже занят в это время: ошибка EXCLUDE (23P01)
-- expect: error 23P01
INSERT INTO casting (actor_id, role_id, show_id, play_id, starts_at, ends_at)
SELECT 1, 31, id, play_id, starts_at, ends_at
FROM shows WHERE hall_id = 2 AND starts_at = '2026-11-05 20:00+03';

--   ( 1, 1, timestamptz '2026-11-05 19:00+03', 1500.00),  -- 1
ROLLBACK;
