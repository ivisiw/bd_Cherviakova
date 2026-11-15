-- Лаба 3. Представления

-- 1. Карточка показа: спектакль, зал, время, цена, занятость зала.
-- Занятыми считаем проданные и забронированные места; возвращённый билет место освобождает.
CREATE OR REPLACE VIEW v_show_card AS
SELECT s.id        AS show_id,
       p.title,
       p.age_limit,
       h.name      AS hall,
       s.starts_at,
       s.ends_at,
       s.base_price,
       s.status,
       h.capacity,
       count(t.id) FILTER (WHERE t.status IN ('sold', 'reserved'))               AS taken,
       h.capacity - count(t.id) FILTER (WHERE t.status IN ('sold', 'reserved'))  AS free_seats
FROM shows s
JOIN plays p ON p.id = s.play_id
JOIN halls h ON h.id = s.hall_id
LEFT JOIN tickets t ON t.show_id = s.id
GROUP BY s.id, p.id, h.id;

-- 2. Состав показа: кто какую роль играет
CREATE OR REPLACE VIEW v_show_cast AS
SELECT s.id        AS show_id,
       p.title,
       s.starts_at,
       r.name      AS role,
       r.is_lead,
       a.full_name AS actor
FROM casting c
JOIN shows  s ON s.id = c.show_id
JOIN plays  p ON p.id = s.play_id
JOIN roles  r ON r.id = c.role_id
JOIN actors a ON a.id = c.actor_id;
