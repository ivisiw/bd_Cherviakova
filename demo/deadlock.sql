-- Лаба 4 ★. Взаимоблокировка: два окна берут две строки в разном порядке.
-- Запуск: dbcheck run demo/deadlock.sql
-- Оба окна в конце откатываются, данные не меняются.

-- [A] Блокирует показ 1
BEGIN;
UPDATE shows SET base_price = base_price WHERE id = 1;

-- [B] Блокирует показ 2
BEGIN;
UPDATE shows SET base_price = base_price WHERE id = 2;

-- [A] Хочет показ 2: ждёт окно B
-- expect: blocked
UPDATE shows SET base_price = base_price WHERE id = 2;

-- [B] Хочет показ 1: круг ожидания, база отменяет эту транзакцию
-- expect: error deadlock
UPDATE shows SET base_price = base_price WHERE id = 1;

-- [B]
ROLLBACK;

-- [A] Окно A дождалось и обновило показ 2; откатываем
ROLLBACK;
