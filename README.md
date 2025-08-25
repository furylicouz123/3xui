# 3X-UI VPN Server

Простое и быстрое развертывание VPN сервера с 3X-UI панелью управления и веб-сайтом.

## Быстрая установка

Для автоматической установки выполните одну команду:

```bash
curl -sSL https://raw.githubusercontent.com/furylicouz123/3xui-full/main/install.sh | bash
```

Или скачайте и запустите вручную:

```bash
wget https://raw.githubusercontent.com/furylicouz123/3xui-full/main/install.sh
chmod +x install.sh
./install.sh
```

## Особенности

- ✅ Один домен для веб-сайта (порт 443) и 3X-UI панели (порт 2053)
- ✅ Автоматическая генерация SSL сертификатов
- ✅ Простая настройка без конфигурационных файлов
- ✅ Docker Compose для легкого управления
- ✅ Nginx как reverse proxy
- ✅ Готовый веб-сайт

## Что включено

- **3X-UI панель** - современная панель управления для Xray
- **Веб-сайт** - готовый сайт с красивым дизайном
- **Nginx** - reverse proxy с SSL поддержкой
- **Docker Compose** - для управления контейнерами

## Доступ к сервисам

После установки:
- **Веб-сайт**: https://ваш-домен:443
- **3X-UI панель**: https://ваш-домен:2053
- **Логин**: admin
- **Пароль**: admin123

## Управление

```bash
# Просмотр статуса
docker compose ps

# Просмотр логов
docker compose logs

# Перезапуск
docker compose restart

# Остановка
docker compose down

# Обновление
docker compose pull && docker compose up -d
```

## Полная очистка

Для полного удаления:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## Структура проекта

```
├── install.sh              # Основной скрипт установки
├── quick-deploy.sh          # Быстрое развертывание
├── cleanup.sh               # Скрипт очистки
├── docker-compose.yml       # Docker Compose конфигурация
├── nginx.conf               # Конфигурация Nginx
├── setup-letsencrypt.sh     # Настройка Let's Encrypt
├── website/                 # Файлы веб-сайта
│   ├── index.html
│   ├── script.js
│   └── assets/
└── docs/                    # Документация
    ├── QUICK-START.md
    ├── TROUBLESHOOTING.md
    └── DEPLOY-INSTRUCTIONS.md
```

## Требования

- Ubuntu/Debian/CentOS сервер
- Root доступ
- Открытые порты: 80, 443, 2053
- Домен с настроенной DNS записью

## Управление через Makefile

Проект включает удобный Makefile для управления VPN сервером:

### Основные команды:
```bash
# Показать все доступные команды
make help

# Полная установка и настройка
make install

# Управление сервисами
make start      # Запуск сервисов
make stop       # Остановка сервисов
make restart    # Перезапуск сервисов
make status     # Статус сервисов
```

### Мониторинг и логи:
```bash
make logs       # Просмотр логов
make logs-f     # Логи в реальном времени
make logs-nginx # Логи только Nginx
make logs-xui   # Логи только 3X-UI
make monitor    # Мониторинг ресурсов
```

### Резервное копирование:
```bash
make backup     # Создать резервную копию
make restore    # Восстановить из копии
```

### SSL сертификаты:
```bash
make ssl-gen    # Генерация SSL сертификатов
```

### Обслуживание:
```bash
make update     # Обновление образов
make clean      # Очистка системы
make cleanup    # Полная очистка (ОСТОРОЖНО!)
make info       # Информация о системе
```

### Работа с контейнерами:
```bash
make shell-nginx   # Подключиться к Nginx
make shell-xui     # Подключиться к 3X-UI
make nginx-test    # Проверить конфигурацию Nginx
make nginx-reload  # Перезагрузить Nginx
```

## Поддержка

Если возникли проблемы, смотрите:
- [Быстрый старт](QUICK-START.md)
- [Устранение неполадок](TROUBLESHOOTING.md)
- [Инструкции по развертыванию](DEPLOY-INSTRUCTIONS.md)

## Лицензия

MIT License