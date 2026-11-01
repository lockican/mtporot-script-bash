```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Настройки прокси
PORT="443"
LOCAL_PORT="8888"
WORKERS="1"

# Каталог, в котором находится скрипт
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Проверяем наличие необходимых программ
for cmd in curl xxd head; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Ошибка: не найдена программа $cmd"
        exit 1
    fi
done

# Проверяем наличие mtproto-proxy
if [[ ! -x "$SCRIPT_DIR/mtproto-proxy" ]]; then
    echo "Ошибка: $SCRIPT_DIR/mtproto-proxy не найден или не исполняемый"
    exit 1
fi

# Скачиваем секрет и конфигурацию Telegram
echo "[1/3] Скачиваем proxy-secret..."
curl -fsSL https://core.telegram.org/getProxySecret \
    -o "$SCRIPT_DIR/proxy-secret"

echo "[2/3] Скачиваем proxy-multi.conf..."
curl -fsSL https://core.telegram.org/getProxyConfig \
    -o "$SCRIPT_DIR/proxy-multi.conf"

# Генерируем секрет пользователей только при первом запуске.
# При повторных запусках сохраняем прежний секрет.
if [[ ! -s "$SCRIPT_DIR/user-secret" ]]; then
    echo "[3/3] Генерируем секрет пользователя..."
    head -c 16 /dev/urandom | xxd -ps -c 32 \
        > "$SCRIPT_DIR/user-secret"
else
    echo "[3/3] Используем существующий секрет пользователя..."
fi

SECRET="$(tr -d '\r\n' < "$SCRIPT_DIR/user-secret")"

echo
echo "========================================"
echo "MTProto Proxy"
echo "========================================"
echo "Порт прокси: $PORT"
echo "Локальный порт: $LOCAL_PORT"
echo "Секрет: $SECRET"
echo "========================================"
echo
echo "Запускаем mtproto-proxy..."

exec "$SCRIPT_DIR/mtproto-proxy" \
    -u nobody \
    -p "$LOCAL_PORT" \
    -H "$PORT" \
    -S "$SECRET" \
    --aes-pwd "$SCRIPT_DIR/proxy-secret" \
    "$SCRIPT_DIR/proxy-multi.conf" \
    -M "$WORKERS"
```
