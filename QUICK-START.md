# Быстрый запуск VPN сервера

## Особенности конфигурации:
- ✅ Один домен для веб-сайта (порт 443) и 3X-UI панели (порт 2053)
- ✅ Ручной ввод домена без использования .env файла
- ✅ Автоматическая генерация SSL сертификатов
- ✅ Простая настройка и развертывание
- ✅ Скрипт полной очистки cleanup.sh

## Полная очистка предыдущей установки:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

Этот скрипт:
- Остановит и удалит все контейнеры
- Удалит Docker образы и volumes
- Очистит директории (ssl, 3x-ui, logs)
- Опционально удалит правила файрвола
- Опционально очистит системные настройки сети

## Быстрое развертывание:

### Вариант 1: Использовать исправленный install.sh
```bash
chmod +x install.sh
./install.sh
```

### Вариант 2: Использовать quick-deploy.sh (рекомендуется)
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Вариант 3: Ручной запуск
```bash
# Создать директории
mkdir -p ssl 3x-ui/db 3x-ui/cert logs/nginx logs/xui website

# Генерация SSL (замените YOUR_DOMAIN)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/domain.key -out ssl/domain.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=VPN/OU=IT/CN=YOUR_DOMAIN"

# Запуск
docker-compose up -d
```

## Доступ к сервисам:
- **Веб-сайт**: https://YOUR_DOMAIN:443
- **3X-UI панель**: https://YOUR_DOMAIN:2053
- **Логин**: admin
- **Пароль**: admin123

## Управление:
```bash
# Просмотр логов
docker-compose logs -f

# Перезапуск
docker-compose restart

# Остановка
docker-compose down

# Обновление
docker-compose pull && docker-compose up -d
```

## Решение проблем

Если возникли проблемы:

1. **Контейнеры не удаляются**: Используйте `./cleanup.sh`
2. **Сайт недоступен (403)**: Проверьте наличие `website/index.html`
3. **Неправильный пароль 3X-UI**: Проверьте `.env` файл
4. **Домен не из переменной**: Убедитесь, что `XUI_DOMAIN` указан в `.env`

Подробное руководство: `TROUBLESHOOTING.md`

## Важно для продакшена:
1. Настройте DNS записи для ваших доменов
2. Замените самоподписанные сертификаты на Let's Encrypt
3. Измените пароли по умолчанию
4. Настройте регулярные бэкапы