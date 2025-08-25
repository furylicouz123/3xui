# Docker Compose: Nginx + 3X-UI VPN Panel

## Описание
Этот Docker Compose файл разворачивает:
- **Nginx** (версия 1.27-alpine) - веб-сервер и обратный прокси
- **3X-UI** (последняя версия) - панель управления VPN с поддержкой VLESS, VMess, Trojan

## 📁 Структура проекта

```
vpn_server/
├── docker-compose.yml     # Основная конфигурация Docker Compose
├── nginx.conf            # Конфигурация Nginx
├── website/              # Статические файлы веб-сайта terminaus.ru
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── assets/
├── ssl/                  # SSL сертификаты
│   ├── cert.pem         # Сертификат для 3X-UI панели
│   ├── key.pem          # Ключ для 3X-UI панели
│   ├── terminaus.ru.crt # Сертификат для terminaus.ru
│   └── terminaus.ru.key # Ключ для terminaus.ru
├── logs/                 # Логи
│   └── nginx/
├── data/                 # Данные 3X-UI
│   └── x-ui/
├── .env.example         # Пример переменных окружения
├── install.sh           # Скрипт автоматической установки
├── Makefile            # Команды для управления проектом
└── README-Docker.md    # Эта документация
```

## 🚀 Быстрый старт

### 1. Подготовка
```bash
# Клонируйте или скопируйте файлы проекта
cd vpn_server

# Создайте необходимые директории
mkdir -p ssl logs/nginx data/x-ui website

# Убедитесь, что папка website содержит ваши статические файлы
# Должен быть как минимум index.html
```

### 2. Настройка SSL сертификатов
```bash
# Для тестирования (самоподписанные сертификаты)
# Сертификат для 3X-UI панели
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=VPN-Server/CN=panel.your-domain.com"

# Сертификат для terminaus.ru
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/terminaus.ru.key \
    -out ssl/terminaus.ru.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=Terminaus/CN=terminaus.ru"

# Для продакшена используйте Let's Encrypt
# certbot certonly --standalone -d panel.your-domain.com
# certbot certonly --standalone -d terminaus.ru
# cp /etc/letsencrypt/live/panel.your-domain.com/fullchain.pem ssl/cert.pem
# cp /etc/letsencrypt/live/panel.your-domain.com/privkey.pem ssl/key.pem
# cp /etc/letsencrypt/live/terminaus.ru/fullchain.pem ssl/terminaus.ru.crt
# cp /etc/letsencrypt/live/terminaus.ru/privkey.pem ssl/terminaus.ru.key
```

### 2. Настройка домена
Отредактируйте `nginx.conf` и замените `your-domain.com` на ваш реальный домен.

### 3. Запуск сервисов
```bash
# Запуск в фоновом режиме
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

## 🌐 Доступ к сервисам

### Веб-сайт terminaus.ru
- **URL**: `https://terminaus.ru`
- **Описание**: Статический веб-сайт
- **Файлы**: `./website/`

### 3X-UI Панель управления
- **URL**: `https://panel.your-domain.com` (замените на ваш домен)
- **Прямой доступ**: `http://your-server-ip:2053`
- **Логин по умолчанию**: `admin`
- **Пароль по умолчанию**: `admin`

⚠️ **Важно**: Сразу после первого входа смените логин и пароль!

## Настройка 3X-UI

### Первоначальная настройка
1. Войдите в панель управления
2. Смените логин и пароль в разделе "Settings"
3. Настройте SSL сертификаты в разделе "Panel Settings"
4. Создайте пользователей в разделе "Inbounds"

### Рекомендуемые настройки безопасности
- Измените порт панели управления (по умолчанию 2053)
- Включите двухфакторную аутентификацию
- Настройте ограничения по IP
- Регулярно обновляйте пароли

## Порты
- **80** - HTTP (редирект на HTTPS)
- **443** - HTTPS (Nginx + 3X-UI)
- **2053** - Прямой доступ к 3X-UI панели

## Мониторинг

### Просмотр логов
```bash
# Логи Nginx
docker-compose logs nginx

# Логи 3X-UI
docker-compose logs xui

# Все логи
docker-compose logs
```

### Статус сервисов
```bash
# Статус контейнеров
docker-compose ps

# Использование ресурсов
docker stats
```

## Обновление

```bash
# Остановка сервисов
docker-compose down

# Обновление образов
docker-compose pull

# Запуск с новыми образами
docker-compose up -d
```

## Резервное копирование

### Создание бэкапа
```bash
# Бэкап конфигурации 3X-UI
docker-compose exec xui tar -czf /tmp/xui-backup.tar.gz /etc/x-ui
docker cp $(docker-compose ps -q xui):/tmp/xui-backup.tar.gz ./xui-backup-$(date +%Y%m%d).tar.gz
```

### Восстановление
```bash
# Восстановление конфигурации
docker cp ./xui-backup-YYYYMMDD.tar.gz $(docker-compose ps -q xui):/tmp/
docker-compose exec xui tar -xzf /tmp/xui-backup-YYYYMMDD.tar.gz -C /
docker-compose restart xui
```

## Устранение неполадок

### Проверка сети
```bash
# Проверка подключения между контейнерами
docker-compose exec nginx ping xui

# Проверка портов
netstat -tlnp | grep -E ':(80|443|2053)'
```

### Частые проблемы
1. **Ошибка SSL**: Проверьте пути к сертификатам в nginx.conf
2. **Недоступна панель**: Убедитесь, что порт 2053 открыт
3. **Проблемы с VPN**: Проверьте настройки iptables и forwarding

## Безопасность

- Используйте сильные пароли
- Регулярно обновляйте образы Docker
- Настройте файрвол (ufw/iptables)
- Используйте реальные SSL сертификаты (Let's Encrypt)
- Ограничьте доступ к панели управления по IP

## Поддержка

- [3X-UI GitHub](https://github.com/MHSanaei/3x-ui)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)