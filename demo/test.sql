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