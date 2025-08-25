# Руководство по устранению неполадок

## Основные проблемы и их решения

### 1. Контейнеры остаются после удаления скрипта

**Проблема**: После удаления файлов проекта контейнеры Docker продолжают работать.

**Решение**: Используйте скрипт очистки:
```bash
./cleanup.sh
# или
make cleanup
```

### 2. Сайт terminaus.ru недоступен (403 Forbidden)

**Проблема**: Контейнер website не может найти файл index.html.

**Решение**: 
1. Убедитесь, что файл `website/index.html` существует
2. Перезапустите контейнеры:
```bash
docker-compose down
docker-compose up -d
```

### 3. Неправильные учетные данные 3X-UI

**Проблема**: В панели отображается admin/admin вместо admin/admin123.

**Решение**: 
1. Проверьте файл `.env`:
```bash
XUI_USERNAME=admin
XUI_PASSWORD=admin123
```
2. Перезапустите контейнер:
```bash
docker-compose restart xui
```

### 4. Домен не берется из переменной

**Проблема**: Скрипт запрашивает домен вручную вместо использования .env файла.

**Решение**: Убедитесь, что в файле `.env` указан домен:
```bash
XUI_DOMAIN=your-domain.com
```

### 5. SSL сертификаты содержат упоминание VPN

**Проблема**: В SSL сертификатах указано "VPN server".

**Решение**: Обновленные скрипты используют нейтральные названия:
- Для 3X-UI: "IT Services"
- Для terminaus.ru: "Terminaus Ltd"

## Команды для диагностики

### Проверка статуса контейнеров
```bash
docker ps
docker-compose ps
```

### Просмотр логов
```bash
# Все сервисы
docker-compose logs

# Конкретный сервис
docker-compose logs nginx
docker-compose logs xui
docker-compose logs website
```

### Проверка сетевых подключений
```bash
# Проверка портов
netstat -tlnp | grep -E ':(80|443|2053)'

# Проверка доступности сервисов
curl -I http://localhost
curl -I https://localhost
curl -I http://localhost:2053
```

### Проверка файлов
```bash
# Структура директорий
tree -L 3

# Проверка SSL сертификатов
openssl x509 -in ssl/xui.crt -text -noout
openssl x509 -in ssl/terminaus.crt -text -noout
```

## Полная переустановка

Если проблемы не решаются:

1. **Полная очистка**:
```bash
./cleanup.sh
```

2. **Новая установка**:
```bash
./quick-deploy.sh
# или
./install.sh
```

## Проверка после установки

1. **Проверьте контейнеры**:
```bash
docker ps
```
Должны работать: `nginx-proxy`, `xui-panel`, `terminaus-website`

2. **Проверьте доступность**:
- https://your-domain.com:2053 - панель 3X-UI
- https://terminaus.ru - веб-сайт

3. **Проверьте логи**:
```bash
docker-compose logs --tail=50
```

## Контакты для поддержки

Если проблемы не решаются, проверьте:
1. Версии Docker и Docker Compose
2. Права доступа к файлам
3. Настройки брандмауэра
4. DNS записи для доменов