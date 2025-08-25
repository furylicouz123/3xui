# 3X-UI VPN Server с автоматическими SSL сертификатами

Полнофункциональный VPN сервер с веб-интерфейсом, автоматическими SSL сертификатами Let's Encrypt и красивым веб-сайтом.

## Быстрая установка

```bash
curl -sSL https://raw.githubusercontent.com/furylicouz123/3xui/main/install.sh | bash
```

**Примечание:** Скрипт автоматически скачает все необходимые файлы из репозитория:
- `docker-compose.yml` - конфигурация Docker контейнеров
- `nginx.conf` - настройки веб-сервера
- `setup-letsencrypt.sh` - скрипт для SSL сертификатов
- `Makefile` - команды управления проектом
- `cleanup.sh` - скрипт очистки
- Файлы веб-сайта (HTML, CSS, JS, изображения)
- `.gitignore` - правила игнорирования файлов

**Преимущества:** Вам не нужно клонировать весь репозиторий или скачивать файлы вручную - одна команда установит всё необходимое!

## ✨ Возможности

- **Автоматические SSL сертификаты** - Let's Encrypt сертификаты получаются автоматически при указании домена
- **Автообновление сертификатов** - настроенное через cron обновление каждый день в 3:00
- **3X-UI панель управления** - современный веб-интерфейс для управления VPN
- **Nginx прокси** - обратный прокси с SSL терминацией
- **Красивый веб-сайт** - готовый к использованию сайт с современным дизайном
- **Docker Compose** - простое развертывание и управление
- **Автоматическая настройка файрвола** - UFW с необходимыми правилами
- **Оптимизация системы** - настройки ядра для лучшей производительности VPN

## 📋 Требования

- Ubuntu 20.04+ / Debian 11+
- Root доступ
- Домен, указывающий на ваш сервер (для SSL сертификатов)
- Открытые порты: 80, 443, 2053

## 🔧 Установка

### Автоматическая установка

1. Запустите скрипт установки:
```bash
curl -sSL https://raw.githubusercontent.com/furylicouz123/3xui/main/install.sh | bash
```

2. Введите ваш домен когда будет запрошено
3. Дождитесь завершения установки
4. Получите доступ к вашим сервисам:
   - Веб-сайт: `https://yourdomain.com`
   - 3X-UI панель: `https://yourdomain.com:2053`

### Ручная установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/furylicouzzz123/3xui-full.git
cd 3xui-full
```

2. Запустите установку:
```bash
sudo ./install.sh
```

## 🔐 Доступ к панели управления

- **URL**: `https://yourdomain.com:2053`
- **Логин**: `admin`
- **Пароль**: `admin`

⚠️ **Важно**: Смените пароль после первого входа!

## 📁 Структура проекта

```
3xui-full/
├── docker-compose.yml      # Docker Compose конфигурация (скачивается автоматически)
├── install.sh             # Скрипт автоматической установки
├── setup-letsencrypt.sh   # Скрипт настройки SSL (скачивается автоматически)
├── Makefile              # Команды для управления (скачивается автоматически)
├── config/
│   └── nginx.conf        # Конфигурация Nginx (скачивается автоматически)
├── website/              # Файлы веб-сайта (скачиваются автоматически)
│   ├── index.html
│   └── assets/
├── ssl/                  # SSL сертификаты
├── 3x-ui/               # Данные 3X-UI
└── logs/                # Логи сервисов
```

**Автоматическое скачивание:** При запуске `install.sh` все необходимые файлы автоматически скачиваются из репозитория GitHub.

## 🛠️ Управление сервисами

### Использование Makefile

```bash
# Запуск всех сервисов
make up

# Остановка всех сервисов
make down

# Перезапуск сервисов
make restart

# Просмотр логов
make logs

# Обновление образов
make update

# Очистка системы
make clean
```

### Использование Docker Compose

```bash
# Запуск сервисов
docker compose up -d

# Остановка сервисов
docker compose down

# Просмотр логов
docker compose logs -f

# Перезапуск конкретного сервиса
docker compose restart nginx-proxy
```

## 🔒 SSL сертификаты

### Автоматическое получение

При установке система автоматически:
1. Устанавливает Certbot
2. Получает SSL сертификаты для вашего домена
3. Настраивает автообновление через cron
4. Создает временные сертификаты если Let's Encrypt недоступен

### Ручное управление сертификатами

```bash
# Получение/обновление сертификатов
./setup-letsencrypt.sh

# Проверка статуса сертификатов
certbot certificates

# Тест обновления
certbot renew --dry-run

# Просмотр логов обновления
tail -f /var/log/letsencrypt-renewal.log
```

## 🔧 Настройка

### Переменные окружения (.env)

```bash
XUI_DOMAIN=yourdomain.com
WEBSITE_DOMAIN=yourdomain.com
```

### Настройка 3X-UI

1. Войдите в панель: `https://yourdomain.com:2053`
2. Смените пароль администратора
3. Настройте пользователей и протоколы VPN
4. Настройте правила маршрутизации

### Настройка веб-сайта

Замените файлы в директории `website/` на ваш контент:
```bash
# Замена главной страницы
cp your-index.html website/index.html

# Добавление ресурсов
cp -r your-assets/* website/assets/

# Перезапуск nginx для применения изменений
docker compose restart nginx-proxy
```

## 🔍 Мониторинг и логи

### Просмотр логов

```bash
# Все логи
docker compose logs -f

# Логи nginx
docker compose logs -f nginx-proxy

# Логи 3X-UI
docker compose logs -f xui

# Логи обновления SSL
tail -f /var/log/letsencrypt-renewal.log
```

### Проверка статуса

```bash
# Статус контейнеров
docker compose ps

# Использование ресурсов
docker stats

# Проверка портов
ss -tlnp | grep -E ':(80|443|2053)'
```

## 🚨 Устранение неполадок

### SSL сертификаты не получены

1. Проверьте DNS записи:
```bash
nslookup yourdomain.com
```

2. Проверьте доступность портов:
```bash
telnet yourdomain.com 80
```

3. Запустите получение сертификатов вручную:
```bash
./setup-letsencrypt.sh
```

### Сервисы не запускаются

1. Проверьте логи:
```bash
docker compose logs
```

2. Проверьте конфигурацию:
```bash
docker compose config
```

3. Перезапустите сервисы:
```bash
docker compose down && docker compose up -d
```

### Проблемы с доступом

1. Проверьте файрвол:
```bash
ufw status
```

2. Проверьте nginx конфигурацию:
```bash
docker compose exec nginx-proxy nginx -t
```

## 🔄 Обновление

```bash
# Обновление образов
docker compose pull
docker compose up -d

# Обновление кода
git pull origin main
docker compose up -d --build
```

## 🗑️ Удаление

```bash
# Остановка и удаление контейнеров
docker compose down -v

# Удаление образов
docker rmi $(docker images -q)

# Удаление файлов
rm -rf /path/to/3xui-full

# Удаление cron задачи
crontab -l | grep -v renew-certs | crontab -
```

## 📞 Поддержка

Если у вас возникли проблемы:

1. Проверьте [Issues](https://github.com/furylicouzzz123/3xui-full/issues)
2. Создайте новый Issue с подробным описанием проблемы
3. Приложите логи и конфигурацию

## 📄 Лицензия

MIT License - см. файл [LICENSE](LICENSE)

## 🤝 Вклад в проект

Приветствуются Pull Request'ы! Пожалуйста:

1. Форкните репозиторий
2. Создайте ветку для вашей функции
3. Сделайте коммит изменений
4. Отправьте Pull Request

---

**Сделано с ❤️ для сообщества VPN пользователей**