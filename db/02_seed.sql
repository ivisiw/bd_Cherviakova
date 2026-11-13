-- Лаба 1. Тестовые данные

INSERT INTO halls (name, capacity) VALUES
  ('Большая сцена', 300),
  ('Камерный зал', 120),
  ('Малая сцена', 80);

INSERT INTO plays (title, author, duration_min, age_limit) VALUES
  ('Ревизор',            'Н. В. Гоголь',          150, 12),  -- 1
  ('Вишнёвый сад',       'А. П. Чехов',           165, 12),  -- 2
  ('Горе от ума',        'А. С. Грибоедов',       170, 12),  -- 3
  ('Гроза',              'А. Н. Островский',      140, 16),  -- 4
  ('Три сестры',         'А. П. Чехов',           160, 12),  -- 5
  ('Мастер и Маргарита', 'М. А. Булгаков',        180, 16),  -- 6
  ('Ромео и Джульетта',  'У. Шекспир',            150, 12),  -- 7
  ('Гамлет',             'У. Шекспир',            190, 16),  -- 8
  ('Чайка',              'А. П. Чехов',           150, 12),  -- 9
  ('На дне',             'М. Горький',            140, 16),  -- 10
  ('Маленький принц',    'А. де Сент-Экзюпери',    90,  6),  -- 11
  ('Женитьба',           'Н. В. Гоголь',          120, 12);  -- 12

INSERT INTO actors (full_name, birth_date, email) VALUES
  ('Иван Орлов',      '1985-03-14', 'orlov@theatre.test'),      -- 1
  ('Мария Соколова',  '1990-07-21', 'sokolova@theatre.test'),   -- 2
  ('Алексей Громов',  '1978-11-02', 'gromov@theatre.test'),     -- 3
  ('Елена Волкова',   '1992-01-30', 'volkova@theatre.test'),    -- 4
  ('Дмитрий Лебедев', '1983-05-09', 'lebedev@theatre.test'),    -- 5
  ('Ольга Миронова',  '1988-09-17', 'mironova@theatre.test'),   -- 6
  ('Сергей Ковалёв',  '1975-12-25', 'kovalev@theatre.test'),    -- 7
  ('Анна Крылова',    '1995-04-06', 'krylova@theatre.test'),    -- 8
  ('Павел Зайцев',    '1981-08-19', 'zaytsev@theatre.test'),    -- 9
  ('Наталья Беляева', '1987-02-11', 'belyaeva@theatre.test'),   -- 10
  ('Андрей Фролов',   '1993-06-28', 'frolov@theatre.test'),     -- 11
  ('Татьяна Назарова','1979-10-03', 'nazarova@theatre.test'),   -- 12
  ('Михаил Седов',    '1986-01-15', 'sedov@theatre.test'),      -- 13
  ('Юлия Комарова',   '1994-03-22', 'komarova@theatre.test'),   -- 14
  ('Виктор Румянцев', '1972-07-07', 'rumyantsev@theatre.test'); -- 15

INSERT INTO roles (play_id, name, is_lead) VALUES
  (1,'Городничий',true),(1,'Хлестаков',true),(1,'Анна Андреевна',false),                -- 1-3
  (2,'Раневская',true),(2,'Лопахин',true),(2,'Трофимов',false),                         -- 4-6
  (3,'Чацкий',true),(3,'Софья',false),(3,'Фамусов',false),                              -- 7-9
  (4,'Катерина',true),(4,'Кабаниха',false),(4,'Борис',false),                           -- 10-12
  (5,'Маша',true),(5,'Ирина',false),(5,'Вершинин',false),                               -- 13-15
  (6,'Мастер',true),(6,'Маргарита',true),(6,'Воланд',true),                             -- 16-18
  (7,'Ромео',true),(7,'Джульетта',true),(7,'Меркуцио',false),                           -- 19-21
  (8,'Гамлет',true),(8,'Офелия',false),(8,'Клавдий',false),                             -- 22-24
  (9,'Нина Заречная',true),(9,'Треплев',true),(9,'Аркадина',false),                     -- 25-27
  (10,'Лука',true),(10,'Сатин',false),(10,'Настя',false),                               -- 28-30
  (11,'Маленький принц',true),(11,'Лётчик',true),(11,'Роза',false),                     -- 31-33
  (12,'Подколесин',true),(12,'Кочкарёв',false),(12,'Агафья Тихоновна',true);            -- 34-36

-- Показы: время окончания считаем по длительности спектакля
INSERT INTO shows (play_id, hall_id, starts_at, ends_at, base_price)
SELECT v.play_id, v.hall_id, v.starts_at,
       v.starts_at + p.duration_min * interval '1 minute', v.base_price
FROM (VALUES
  ( 1, 1, timestamptz '2026-11-05 19:00+03', 1500.00),  -- 1
  ( 2, 2, timestamptz '2026-11-06 19:00+03', 1200.00),  -- 2
  ( 3, 3, timestamptz '2026-11-07 18:00+03',  800.00),  -- 3
  ( 4, 1, timestamptz '2026-11-08 18:00+03', 1800.00),  -- 4
  ( 5, 2, timestamptz '2026-11-12 19:00+03', 1100.00),  -- 5
  ( 6, 3, timestamptz '2026-11-13 19:00+03',  900.00),  -- 6
  ( 7, 1, timestamptz '2026-11-14 19:00+03', 2000.00),  -- 7
  ( 8, 2, timestamptz '2026-11-15 15:00+03', 1000.00),  -- 8
  ( 9, 3, timestamptz '2026-11-19 19:00+03',  950.00),  -- 9
  (10, 1, timestamptz '2026-11-20 19:00+03', 1700.00),  -- 10
  (11, 2, timestamptz '2026-11-21 19:00+03', 1300.00),  -- 11
  (12, 3, timestamptz '2026-11-22 18:00+03',  700.00),  -- 12
  ( 1, 1, timestamptz '2026-11-26 19:00+03', 1500.00),  -- 13
  ( 2, 2, timestamptz '2026-11-27 19:00+03', 1200.00)   -- 14
) AS v(play_id, hall_id, starts_at, base_price)
JOIN plays p ON p.id = v.play_id
ORDER BY v.starts_at;

-- Распределение ролей: (показ, роль, актёр)
INSERT INTO casting (actor_id, role_id, show_id, play_id, starts_at, ends_at)
SELECT c.actor_id, c.role_id, c.show_id, s.play_id, s.starts_at, s.ends_at
FROM (VALUES
  ( 1,  1,  1), ( 1,  2,  2), ( 1,  3,  3),
  ( 2,  4,  4), ( 2,  5,  5), ( 2,  6,  6),
  ( 3,  7,  7), ( 3,  8,  8), ( 3,  9,  9),
  ( 4, 10, 10), ( 4, 11,  3), ( 4, 12, 11),
  ( 5, 13, 12), ( 5, 14, 13), ( 5, 15, 14),
  ( 6, 16, 15), ( 6, 17,  2), ( 6, 18,  1),
  ( 7, 19,  7), ( 7, 20,  8), ( 7, 21,  9),
  ( 8, 22,  3), ( 8, 23, 10), ( 8, 24,  5),
  ( 9, 25, 14), ( 9, 26, 13), ( 9, 27, 12),
  (10, 28, 11), (10, 29, 15), (10, 30,  4),
  (11, 31,  6), (11, 32,  1), (11, 33,  2),
  (12, 34,  7), (12, 35,  9), (12, 36, 10),
  (13,  1,  1), (13,  2,  3), (13,  3,  4),
  (14,  4,  6), (14,  5,  5), (14,  6,  4)
) AS c(show_id, role_id, actor_id)
JOIN shows s ON s.id = c.show_id;

-- Билеты: 80 на каждый из 14 показов = 1120 строк (generate_series)
INSERT INTO tickets (show_id, seat_row, seat_number, price, buyer_name, status, sold_at)
SELECT s.id,
       (n - 1) / 10 + 1,
       (n - 1) % 10 + 1,
       round(s.base_price * CASE WHEN n <= 20 THEN 1.5 WHEN n <= 50 THEN 1.0 ELSE 0.7 END, 2),
       (ARRAY['Смирнов А.','Кузнецова М.','Попов Д.','Васильева Е.',
              'Новиков И.','Морозова О.','Павлов С.','Фёдорова Т.'])[1 + (s.id * n) % 8],
       CASE WHEN n % 17 = 0 THEN 'returned'
            WHEN n % 9  = 0 THEN 'reserved'
            ELSE 'sold' END,
       s.starts_at - (n % 30 + 1) * interval '1 day'
FROM shows s
CROSS JOIN generate_series(1, 80) AS n;


-- Лаба 2: «сироты» для запросов LEFT JOIN ... IS NULL и NOT EXISTS.
-- Спектакль, у которого ещё нет показов (id 13), и три его роли (id 37-39).
INSERT INTO plays (title, author, duration_min, age_limit) VALUES
  ('Дядя Ваня', 'А. П. Чехов', 150, 12);                                -- 13
INSERT INTO roles (play_id, name, is_lead) VALUES
  (13,'Войницкий',true),(13,'Астров',true),(13,'Соня',false);           -- 37-39
-- Актёр, который пока не занят ни в одном показе (id 16).
INSERT INTO actors (full_name, birth_date, email) VALUES
  ('Кирилл Лазарев', '1996-08-12', 'lazarev@theatre.test');