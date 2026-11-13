1. Обнови базу и чекер:
   ```powershell
   py -m pip install --upgrade git+https://github.com/bozhedom/dbcheck@v1
   ```
2. Пересоздай базу:
   ```powershell
   docker compose down -v
   docker compose up -d
   ```
3. Открой консоль базы и включи показ NULL:
   ```powershell
   docker compose exec db psql -U postgres -d app
   ```
   ```sql
   \pset null 'Ø'
   ```
4. Для проверки:
      docker compose exec db psql -U postgres -d app -f /demo/test.sql
      
5. Схема под рукой: `\d shows`, `\d casting`. Столбцы:
   - `halls(id, name, capacity)`
   - `plays(id, title, author, duration_min, age_limit)`
   - `actors(id, full_name, birth_date, email)`
   - `roles(id, play_id, name, is_lead)`
   - `shows(id, play_id, hall_id, starts_at, ends_at, base_price, status)`
   - `casting(actor_id, role_id, show_id, play_id, starts_at, ends_at)`
   - `tickets(id, show_id, seat_row, seat_number, price, buyer_name, status, sold_at)`


## Прогон и сверка

1. Прогони сценарий: `py -m dbcheck run demo/lab2.sql --sql`.
2. Потом `py -m dbcheck --lab 2 --stars`.