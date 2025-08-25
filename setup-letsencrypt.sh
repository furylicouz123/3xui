#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен от имени root"
        exit 1
    fi
}

# Настройка Let's Encrypt сертификатов
setup_letsencrypt() {
    print_status "Настройка SSL сертификатов через Let's Encrypt..."
    
    # Загружаем переменные из .env
    if [[ -f ".env" ]]; then
        source .env
    else
        print_error "Файл .env не найден!"
        exit 1
    fi
    
    # Проверяем наличие необходимых переменных
    if [[ -z "$XUI_DOMAIN" ]] || [[ -z "$WEBSITE_DOMAIN" ]]; then
        print_error "Домены не настроены в .env файле!"
        print_status "Убедитесь, что в .env файле указаны:"
        print_status "XUI_DOMAIN=ваш-домен-для-панели.com"
        print_status "WEBSITE_DOMAIN=ваш-домен-для-сайта.com"
        exit 1
    fi
    
    # Остановка nginx для освобождения портов 80 и 443
    print_status "Остановка nginx для получения сертификатов..."
    docker compose stop nginx-proxy 2>/dev/null || true
    
    # Установка certbot если не установлен
    if ! command -v certbot &> /dev/null; then
        print_status "Установка certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Создание директории для SSL если не существует
    mkdir -p ssl
    
    # Получение сертификатов Let's Encrypt
    print_status "Получение SSL сертификата для $XUI_DOMAIN..."
    certbot certonly --standalone --non-interactive --agree-tos \
        --email admin@$XUI_DOMAIN \
        -d $XUI_DOMAIN
    
    if [[ $? -eq 0 ]]; then
        print_success "Сертификат для $XUI_DOMAIN получен успешно"
    else
        print_error "Ошибка получения сертификата для $XUI_DOMAIN"
        exit 1
    fi
    
    print_status "Получение SSL сертификата для $WEBSITE_DOMAIN..."
    certbot certonly --standalone --non-interactive --agree-tos \
        --email admin@$WEBSITE_DOMAIN \
        -d $WEBSITE_DOMAIN
    
    if [[ $? -eq 0 ]]; then
        print_success "Сертификат для $WEBSITE_DOMAIN получен успешно"
    else
        print_error "Ошибка получения сертификата для $WEBSITE_DOMAIN"
        exit 1
    fi
    
    # Копирование сертификатов в нужные директории
    print_status "Копирование сертификатов..."
    cp /etc/letsencrypt/live/$XUI_DOMAIN/privkey.pem ssl/xui.key
    cp /etc/letsencrypt/live/$XUI_DOMAIN/fullchain.pem ssl/xui.crt
    cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/privkey.pem ssl/terminaus.key
    cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/fullchain.pem ssl/terminaus.crt
    
    # Установка правильных прав доступа
    chmod 600 ssl/*.key
    chmod 644 ssl/*.crt
    
    # Обновление конфигурации Nginx
    print_status "Обновление конфигурации Nginx..."
    sed -i "s/your-domain.com/$XUI_DOMAIN/g" nginx.conf
    sed -i "s/terminaus.ru/$WEBSITE_DOMAIN/g" nginx.conf
    
    # Запуск nginx обратно
    print_status "Запуск nginx..."
    docker compose up -d nginx-proxy
    
    print_success "SSL сертификаты Let's Encrypt настроены успешно!"
    print_status "Сертификаты будут автоматически обновляться через cron"
    
    # Настройка автообновления сертификатов
    setup_auto_renewal
}

# Настройка автообновления сертификатов
setup_auto_renewal() {
    print_status "Настройка автообновления сертификатов..."
    
    # Создание скрипта обновления
    cat > /usr/local/bin/renew-certs.sh << 'EOF'
#!/bin/bash
# Скрипт автообновления Let's Encrypt сертификатов

cd /opt/vpn-server || exit 1

# Загрузка переменных окружения
source .env

# Остановка nginx
docker compose stop nginx-proxy

# Обновление сертификатов
certbot renew --quiet

# Копирование обновленных сертификатов
cp /etc/letsencrypt/live/$XUI_DOMAIN/privkey.pem ssl/xui.key
cp /etc/letsencrypt/live/$XUI_DOMAIN/fullchain.pem ssl/xui.crt
cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/privkey.pem ssl/terminaus.key
cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/fullchain.pem ssl/terminaus.crt

# Установка прав доступа
chmod 600 ssl/*.key
chmod 644 ssl/*.crt

# Запуск nginx
docker compose up -d nginx-proxy
EOF
    
    chmod +x /usr/local/bin/renew-certs.sh
    
    # Добавление задачи в cron
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/renew-certs.sh") | crontab -
    
    print_success "Автообновление сертификатов настроено (каждый день в 3:00)"
}

# Основная функция
main() {
    clear
    echo "======================================"
    echo "    Настройка Let's Encrypt SSL"
    echo "======================================"
    echo
    
    check_root
    setup_letsencrypt
    
    echo
    echo "======================================"
    echo -e "${GREEN}Настройка SSL завершена!${NC}"
    echo "======================================"
    echo
    echo "Ваши сайты теперь доступны по HTTPS:"
    echo "- Веб-сайт: https://$WEBSITE_DOMAIN"
    echo "- 3X-UI панель: https://$XUI_DOMAIN"
    echo
    echo "Полезные команды:"
    echo "- Проверка сертификатов: certbot certificates"
    echo "- Ручное обновление: /usr/local/bin/renew-certs.sh"
    echo "- Проверка cron: crontab -l"
    echo
}

# Запуск скрипта
main "$@"