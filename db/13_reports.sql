-- Лаба 3 ★. Отчёт и поиск

-- Материализованное представление: выручка с проданных билетов по месяцам.
-- Хранит снимок; после изменения билетов обновляется командой REFRESH MATERIALIZED VIEW.
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_revenue AS
SELECT date_trunc('month', t.sold_at) AS month,
       count(*)                       AS tickets_sold,
       sum(t.price)                   AS revenue
FROM tickets t
WHERE t.status = 'sold'
GROUP BY 1
ORDER BY 1;

-- Поиск показов по фильтрам. Любой фильтр можно не передавать.
CREATE OR REPLACE FUNCTION find_shows(
    p_hall       text        DEFAULT NULL,   -- точное название зала
    p_title      text        DEFAULT NULL,   -- часть названия спектакля
    p_from       timestamptz DEFAULT NULL,   -- показы не раньше
    p_to         timestamptz DEFAULT NULL,   -- показы раньше этого момента
    p_max_price  numeric     DEFAULT NULL,   -- базовая цена не выше
    p_only_free  boolean     DEFAULT false   -- только показы со свободными местами
)
RETURNS TABLE (show_id integer, title text, hall text, starts_at timestamptz,
               base_price numeric, status text, free_seats integer)
LANGUAGE sql
STABLE
AS $$
    SELECT v.show_id, v.title, v.hall, v.starts_at, v.base_price, v.status, v.free_seats::integer
    FROM v_show_card v
    WHERE (p_hall      IS NULL OR v.hall = p_hall)
      AND (p_title     IS NULL OR v.title ILIKE '%' || p_title || '%')
      AND (p_from      IS NULL OR v.starts_at >= p_from)
      AND (p_to        IS NULL OR v.starts_at <  p_to)
      AND (p_max_price IS NULL OR v.base_price <= p_max_price)
      AND (NOT p_only_free OR v.free_seats > 0)
    ORDER BY v.starts_at;
$$;
