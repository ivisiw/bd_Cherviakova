-- Лаба 2. Запросы к базе «Театр». Бланк: впиши свои запросы вместо TODO.
-- Формат шага: вопрос, строка expect, затем запрос (см. docs/scenarios.md).
-- Время суток считаем по Москве: показы заданы в +03, а сервер работает в UTC.

-- ============================================================
-- JOIN
-- ============================================================

-- 1. Какие спектакли и когда идут в афише?
-- expect: rows 14
SELECT p.title, s.starts_at, s.base_price
FROM shows s
JOIN plays p ON p.id = s.play_id
ORDER BY s.starts_at;


-- 2. Кто какую роль играет в показе «Ревизора» 5 ноября?
-- expect: rows 3
SELECT p.title, s.starts_at, a.full_name AS actor, r.name AS role
FROM casting c
JOIN actors a ON a.id = c.actor_id
JOIN roles  r ON r.id = c.role_id
JOIN shows  s ON s.id = c.show_id
JOIN plays  p ON p.id = s.play_id
WHERE p.title = 'Ревизор'
   AND ((s.starts_at AT TIME ZONE 'Europe/Moscow')::date = DATE('2026-11-05'))
ORDER BY a.full_name;


-- 3. Какие показы в Большой сцене стоят от 1500 рублей и проходят вечером (с 18:00)?
-- expect: rows >= 1
SELECT p.title, h.name AS hall, s.starts_at, s.base_price
FROM shows s
JOIN plays p ON p.id = s.play_id
JOIN halls h ON h.id = s.hall_id
WHERE h.name = 'Большая сцена'
   AND ((s.starts_at AT TIME ZONE 'Europe/Moscow')::time >= TIME'18:00')
   AND (s.base_price >= 1500)
ORDER BY p.title;

-- ============================================================
-- GROUP BY
-- ============================================================

-- 4. Сколько показов у каждого спектакля?
-- expect: rows 12
SELECT p.id, p.title, count(*) AS shows_count
FROM plays p
JOIN shows s ON s.play_id = p.id
GROUP BY p.id, p.title
ORDER BY shows_count DESC, p.title;

-- 5. Какие актёры заняты больше чем в трёх показах?
-- expect: rows 3
SELECT a.id, a.full_name, count(*) AS shows_count
FROM actors a
JOIN casting c ON a.id = c.actor_id
GROUP BY a.id, a.full_name
    HAVING count(*) > 3
ORDER BY shows_count DESC, a.full_name;

-- ============================================================
-- «Сироты» и подзапросы
-- ============================================================

-- 6. Какие спектакли ещё не поставлены ни в один показ?
-- expect: rows 1
SELECT p.id, p.title
FROM plays p
LEFT JOIN shows s ON s.play_id = p.id
WHERE s.id IS NULL;
 
-- 7. Какие актёры играют в спектаклях Чехова?
-- expect: rows >= 1
SELECT a.id, a.full_name
FROM actors a
WHERE a.id IN (
    SELECT c.actor_id
    FROM casting c
    WHERE c.play_id IN (SELECT id FROM plays WHERE author LIKE '%Чехов%')
)
ORDER BY a.full_name;
 
-- 8. Какие актёры пока не заняты ни в одном показе?
-- expect: rows 1
SELECT a.id, a.full_name
FROM actors a
WHERE NOT EXISTS (SELECT 1 FROM casting c WHERE c.actor_id = a.id);
 
-- 9. Какие пять показов самые дорогие среди тех, что дороже средней цены?
-- expect: rows 5
SELECT p.title, s.starts_at, s.base_price
FROM shows s
JOIN plays p ON p.id = s.play_id
WHERE s.base_price > (SELECT avg(base_price) FROM shows)
ORDER BY s.base_price DESC, s.starts_at
LIMIT 5;

-- ============================================================
-- Изменение данных (всё откатывается: ROLLBACK, а не COMMIT)
-- ============================================================

-- 10. Ставим «Дядя Ваня» на Малую сцену 1 декабря: сколько показов было и стало?
-- expect: value 15
BEGIN;
SELECT count(*) AS show_before FROM shows;
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
SELECT p.id, h.id,
    TIMESTAMPTZ '2026-12-01 19:00+03',
    TIMESTAMPTZ '2026-12-01 19:00+03' + p.duration_min * INTERVAL '1 minute',
    900.00
FROM plays p, halls h
WHERE p.title = 'Дядя Ваня' AND h.name = 'Малая сцена';
SELECT count(*) AS show_after FROM shows;
ROLLBACK;

-- 11. Вечерние показы (с 18:00) дорожают на 10%: средняя базовая цена до и после
-- expect: rows 1
BEGIN;
SELECT round(avg(s.base_price), 2) AS price_before   
FROM shows s
WHERE ((s.starts_at AT TIME ZONE 'Europe/Moscow')::time >= TIME'18:00');
UPDATE shows s
SET base_price = round(base_price * 1.1, 2)
WHERE ((s.starts_at AT TIME ZONE 'Europe/Moscow')::time >= TIME'18:00');
SELECT round(avg(s.base_price), 2) AS price_after  
FROM shows s
WHERE ((s.starts_at AT TIME ZONE 'Europe/Moscow')::time >= TIME'18:00');
ROLLBACK;

-- 12. Убираем из базы возвращённые билеты на первый показ: сколько их было и осталось?
-- expect: value 0
BEGIN;
SELECT count(*) AS returned_tickets_before
FROM tickets
WHERE show_id = 1 AND status = 'returned';
DELETE FROM tickets 
WHERE show_id = 1 AND status = 'returned';
SELECT count(*) AS returned_tickets_after
FROM tickets
WHERE show_id = 1 AND status = 'returned';
ROLLBACK;

-- ============================================================
-- ★ CTE и оконные функции
-- ============================================================

-- 13. Три самых дорогих показа в каждом зале (WITH + ROW_NUMBER() OVER PARTITION BY)
-- expect: rows 9
WITH ranked AS (
    SELECT h.name AS hall, p.title, s.base_price, s.starts_at, row_number() OVER (
               PARTITION BY h.id
               ORDER BY s.base_price DESC, s.starts_at) AS rn
    FROM shows s
    JOIN plays p ON p.id = s.play_id
    JOIN halls h ON h.id = s.hall_id
)
SELECT hall, rn AS place, title, base_price, starts_at
FROM ranked
WHERE rn <= 3
ORDER BY hall, rn;

-- 14. Выручка с проданных билетов по дням и накопительный итог
-- expect: rows >= 10
WITH daily AS (
    SELECT sold_at::date AS day,
           sum(price) AS sum_price
    FROM tickets
    WHERE status = 'sold'
    GROUP BY sold_at::date
)
SELECT day, sum_price, sum(sum_price) OVER (ORDER BY day) AS running_total
FROM daily
ORDER BY day;

-- ============================================================
-- ★★ Аналитика
-- ============================================================

-- 15. Сводка по спектаклям: билетов всего, возвращённых и дорогих (от 2000 руб.) и доля каждых в процентах
-- expect: rows 12
SELECT p.title,
    count(*) AS tickets_total, 
    count(*) FILTER (WHERE t.status = 'returned') AS returned_tickets,
    count(*) FILTER (WHERE t.price >= 2000) AS expensive_tickets,
    round(100.0 * count(*) FILTER (WHERE t.status = 'returned') / count(*), 1) AS percent_returned_tickets,
    round(100.0 * count(*) FILTER (WHERE t.price >= 2000) / count(*), 1) AS percent_expensive_tickets
FROM tickets t
JOIN shows s ON t.show_id = s.id
JOIN plays p ON s.play_id = p.id
GROUP BY p.id, p.title
ORDER BY percent_expensive_tickets DESC, p.title;

-- 16. Помесячная динамика выручки и изменение к прошлому месяцу в процентах
-- expect: rows >= 2
WITH monthly AS (
    SELECT date_trunc('month', sold_at) AS month, sum(price) AS total_price
    FROM tickets
    WHERE status = 'sold'
    GROUP BY 1
    )
SELECT to_char(month, 'YYYY-MM') AS month,
    total_price,
    LAG(total_price) OVER (ORDER BY month) AS prev_total_price,
    round(100.0 * (total_price - LAG(total_price) OVER (ORDER BY month))
             / LAG(total_price) OVER (ORDER BY month), 1) AS change_pct
FROM monthly
ORDER BY month;

-- 17. Календарь ноября: сколько показов в каждый день, включая дни без показов
-- expect: rows 30

WITH RECURSIVE days AS(
    SELECT DATE '2026-11-01' AS day
    UNION ALL
    SELECT day + 1 
    FROM days WHERE day < DATE '2026-11-30'
)
SELECT d.day, count(s.id) AS shows_count
FROM days d
LEFT JOIN shows s ON (s.starts_at AT TIME ZONE 'Europe/Moscow')::date = d.day
GROUP BY d.day
ORDER BY d.day; 