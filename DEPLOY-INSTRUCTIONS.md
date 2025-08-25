# 🚀 Инструкция по развертыванию VPN сервера с веб-сайтом

## 📋 Что включено в проект

- **Nginx** - веб-сервер и обратный прокси
- **3X-UI** - панель управления VPN (VLESS, VMess, Trojan)
- **Веб-сайт terminaus.ru** - статический сайт
- **SSL сертификаты** для обоих доменов
- **Docker Compose** для оркестрации

## 🔧 Развертывание на сервере

### 1. Копирование файлов на сервер

```bash
# Метод 1: SCP (рекомендуется)
scp -r c:\load\vpn_page\* root@185.221.153.162:/root/vpn_server/

# Метод 2: Создание архива и копирование
tar -czf vpn_server.tar.gz -C c:\load\vpn_page .
scp vpn_server.tar.gz root@185.221.153.162:/root/
ssh root@185.221.153.162 "cd /root && tar -xzf vpn_server.tar.gz && rm vpn_server.tar.gz"

# Метод 3: Rsync (если доступен)
rsync -avz --progress c:/load/vpn_page/ root@185.221.153.162:/root/vpn_server/
```

### 2. Подключение к серверу и установка

```bash
# Подключение к серверу
ssh root@185.221.153.162

# Переход в директорию проекта
cd /root/vpn_server

# Запуск автоматической установки
chmod +x install.sh
./install.sh
```

### 3. Что делает скрипт установки

1. ✅ Проверяет права root
2. 🐳 Устанавливает Docker и Docker Compose
3. 📁 Создает необходимые директории
4. 🔐 Генерирует SSL сертификаты:
   - Для 3X-UI панели (ваш домен)
   - Для terminaus.ru
5. 🔥 Настраивает firewall (UFW)
6. ⚙️ Оптимизирует систему для VPN
7. 🚀 Запускает все сервисы

### 4. Настройка DNS записей

Добавьте A-записи в DNS:
```
terminaus.ru        A    185.221.153.162
www.terminaus.ru    A    185.221.153.162
panel.your-domain.com A  185.221.153.162  # Замените на ваш домен
```

## 🌐 Доступ к сервисам

### Веб-сайт terminaus.ru
- **URL**: https://terminaus.ru
- **Описание**: Статический веб-сайт
- **Файлы**: `/root/vpn_server/website/`

### 3X-UI Панель управления
- **URL**: https://panel.your-domain.com (замените на ваш домен)
- **Логин**: `admin`
- **Пароль**: `admin`
- ⚠️ **Важно**: Смените пароль после первого входа!

## 🛠️ Управление проектом

### Использование Makefile

```bash
# Запуск всех сервисов
make up

# Остановка сервисов
make down

# Перезапуск
make restart

# Просмотр логов
make logs

# Обновление веб-сайта
make website-update

# Создание резервной копии
make backup

# Генерация SSL сертификатов
make ssl-gen

# Подключение к контейнерам
make shell-nginx    # Nginx
make shell-xui      # 3X-UI
make shell-website  # Веб-сайт
```

### Ручное управление Docker Compose

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Просмотр статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f

# Перезапуск конкретного сервиса
docker-compose restart website
docker-compose restart nginx
docker-compose restart xui
```

## 🔒 Настройка SSL для продакшена

### Использование Let's Encrypt

```bash
# Установка Certbot
apt update && apt install -y certbot

# Остановка Nginx временно
docker-compose stop nginx

# Получение сертификатов
certbot certonly --standalone -d terminaus.ru -d www.terminaus.ru
certbot certonly --standalone -d panel.your-domain.com

# Копирование сертификатов
cp /etc/letsencrypt/live/terminaus.ru/fullchain.pem ssl/terminaus.ru.crt
cp /etc/letsencrypt/live/terminaus.ru/privkey.pem ssl/terminaus.ru.key
cp /etc/letsencrypt/live/panel.your-domain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/panel.your-domain.com/privkey.pem ssl/key.pem

# Запуск Nginx
docker-compose start nginx
```

### Автоматическое обновление сертификатов

```bash
# Создание скрипта обновления
cat > /root/renew-certs.sh << 'EOF'
#!/bin/bash
cd /root/vpn_server
docker-compose stop nginx
certbot renew --quiet
cp /etc/letsencrypt/live/terminaus.ru/fullchain.pem ssl/terminaus.ru.crt
cp /etc/letsencrypt/live/terminaus.ru/privkey.pem ssl/terminaus.ru.key
cp /etc/letsencrypt/live/panel.your-domain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/panel.your-domain.com/privkey.pem ssl/key.pem
docker-compose start nginx
EOF

chmod +x /root/renew-certs.sh

# Добавление в crontab (обновление каждые 2 месяца)
echo "0 3 1 */2 * /root/renew-certs.sh" | crontab -
```

## 📝 Обновление веб-сайта

### Обновление файлов сайта

```bash
# Копирование новых файлов
scp -r /path/to/new/website/* root@185.221.153.162:/root/vpn_server/website/

# Перезапуск контейнера веб-сайта
ssh root@185.221.153.162 "cd /root/vpn_server && docker-compose restart website"
```

## 🔍 Мониторинг и логи

```bash
# Просмотр логов всех сервисов
docker-compose logs -f

# Логи конкретного сервиса
docker-compose logs -f nginx
docker-compose logs -f website
docker-compose logs -f xui

# Статус контейнеров
docker-compose ps

# Использование ресурсов
docker stats
```

## 🚨 Устранение неполадок

### Проблемы с SSL
```bash
# Проверка сертификатов
openssl x509 -in ssl/terminaus.ru.crt -text -noout
openssl x509 -in ssl/cert.pem -text -noout

# Проверка конфигурации Nginx
docker-compose exec nginx nginx -t
```

### Проблемы с доступом
```bash
# Проверка портов
ss -tlnp | grep -E ':(80|443|2053)'

# Проверка firewall
ufw status

# Проверка DNS
nslookup terminaus.ru
nslookup panel.your-domain.com
```

### Перезапуск всех сервисов
```bash
docker-compose down
docker-compose up -d
```

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи: `docker-compose logs -f`
2. Убедитесь, что все порты открыты: `ufw status`
3. Проверьте DNS записи
4. Убедитесь, что SSL сертификаты действительны

---

✅ **Готово!** Ваш VPN сервер с веб-сайтом terminaus.ru развернут и готов к работе.