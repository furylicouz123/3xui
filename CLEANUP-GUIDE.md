# Руководство по очистке и переустановке

## Быстрая очистка

### Способ 1: Использование скрипта cleanup.sh
```bash
chmod +x cleanup.sh
./cleanup.sh
```

### Способ 2: Использование Makefile
```bash
make cleanup
```

### Способ 3: Ручная очистка
```bash
# Остановка сервисов
docker-compose down -v --remove-orphans

# Удаление контейнеров
docker rm -f nginx-proxy xui-panel website-service

# Удаление образов
docker rmi nginx:1.27-alpine ghcr.io/mhsanaei/3x-ui:latest

# Очистка системы Docker
docker system prune -af

# Удаление файлов
rm -rf ssl/ 3x-ui/ logs/ .env
```

## Что удаляет скрипт cleanup.sh:

### Обязательно удаляется:
- ✅ Все Docker контейнеры проекта
- ✅ Docker образы (nginx, 3x-ui)
- ✅ Docker volumes и networks
- ✅ Директории: ssl/, 3x-ui/, logs/
- ✅ Файл .env

### Опционально (с подтверждением):
- 🔄 Правила файрвола (порты 80, 443, 2053)
- 🔄 Системные настройки сети (sysctl.conf)

## После очистки - новая установка:

### Быстрая установка:
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Полная установка:
```bash
chmod +x install.sh
./install.sh
```

### Ручная установка:
```bash
# Создание директорий
mkdir -p ssl 3x-ui/db 3x-ui/cert logs/nginx logs/xui website

# Генерация SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/xui.key -out ssl/xui.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=VPN/OU=IT/CN=YOUR_DOMAIN"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/terminaus.key -out ssl/terminaus.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=VPN/OU=IT/CN=terminaus.ru"

# Запуск
docker-compose up -d
```

## Проверка очистки:

```bash
# Проверка контейнеров
docker ps -a | grep -E "nginx|xui|website"

# Проверка образов
docker images | grep -E "nginx|3x-ui"

# Проверка директорий
ls -la | grep -E "ssl|3x-ui|logs"

# Проверка файрвола
ufw status | grep -E "80|443|2053"
```

## Устранение проблем:

### Если контейнеры не удаляются:
```bash
docker kill $(docker ps -q)
docker rm -f $(docker ps -aq)
```

### Если образы не удаляются:
```bash
docker rmi -f $(docker images -q)
```

### Если директории не удаляются:
```bash
sudo rm -rf ssl/ 3x-ui/ logs/
```

### Полная очистка Docker:
```bash
docker system prune -af --volumes
docker network prune -f
docker volume prune -f
```