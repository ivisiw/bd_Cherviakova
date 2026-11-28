# Лаба 4 ★★. Резервная копия и восстановление в чистую базу.
# Запуск из корня репозитория:  .\scripts\backup_restore.ps1
#
# Что делает:
#   1) pg_dump: копия базы app в сжатом формате (-Fc) внутри контейнера;
#   2) копирует файл на хост в backup\theatre.dump;
#   3) создаёт ЧИСТУЮ базу app_restore и восстанавливает копию через pg_restore;
#   4) сравнивает числа в app и app_restore: данные и политика RLS на месте;
#   5) удаляет app_restore.

$ErrorActionPreference = 'Stop'

function Invoke-Step([string]$Title, [scriptblock]$Action) {
    Write-Host "==> $Title"
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "Шаг не удался: $Title" }
}

$dump = '/tmp/theatre.dump'
# билеты | показы | состав | политики RLS на ticket
$counts = "SELECT (SELECT count(*) FROM tickets) || '|' || (SELECT count(*) FROM shows) || '|' || (SELECT count(*) FROM casting) || '|' || (SELECT count(*) FROM pg_policies WHERE tablename = 'tickets')"

Invoke-Step 'pg_dump: копия базы app' {
    docker compose exec -T db pg_dump -U postgres -d app -Fc -f $dump
}

New-Item -ItemType Directory -Force -Path backup | Out-Null
Invoke-Step 'копируем файл на хост: backup\theatre.dump' {
    docker compose cp "db:$dump" "backup/theatre.dump"
}

Invoke-Step 'удаляем старую app_restore, если была' {
    docker compose exec -T db psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS app_restore"
}
Invoke-Step 'создаём чистую базу app_restore' {
    docker compose exec -T db psql -U postgres -d postgres -c "CREATE DATABASE app_restore"
}
Invoke-Step 'pg_restore: восстанавливаем копию в app_restore' {
    docker compose exec -T db pg_restore -U postgres -d app_restore --no-owner $dump
}

$before = (docker compose exec -T db psql -U postgres -d app -At -c $counts) -join ''
$after  = (docker compose exec -T db psql -U postgres -d app_restore -At -c $counts) -join ''
Write-Host "app          : $before"
Write-Host "app_restore  : $after"

Invoke-Step 'удаляем app_restore' {
    docker compose exec -T db psql -U postgres -d postgres -c "DROP DATABASE app_restore"
}

if ($before -eq $after) {
    Write-Host 'OK: данные и политика RLS восстановлены полностью' -ForegroundColor Green
} else {
    Write-Host 'ОШИБКА: числа в app и app_restore различаются' -ForegroundColor Red
    exit 1
}
