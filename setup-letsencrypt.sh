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
        print_status "Запустите сначала install.sh для создания конфигурации"
        exit 1
    fi
    
    # Проверяем наличие необходимых переменных
    if [[ -z "$WEBSITE_DOMAIN" ]]; then
        print_error "Домен не настроен в .env файле!"
        print_status "Убедитесь, что в .env файле указан:"
        print_status "WEBSITE_DOMAIN=ваш-домен.com"
        exit 1
    fi
    
    DOMAIN=$WEBSITE_DOMAIN
    
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
    print_status "Получение SSL сертификата для $DOMAIN..."
    
    # Проверка DNS перед получением сертификата
    print_status "Проверка DNS записи для $DOMAIN..."
    DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
    SERVER_IP=$(curl -s ifconfig.me)
    
    if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
        print_warning "DNS запись для $DOMAIN указывает на $DOMAIN_IP, но сервер имеет IP $SERVER_IP"
        print_warning "Убедитесь, что DNS запись настроена правильно"
        read -p "Продолжить получение сертификата? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Отменено пользователем"
            exit 1
        fi
    else
        print_success "DNS запись настроена правильно"
    fi
    
    # Получение сертификата
    if certbot certonly --standalone --non-interactive --agree-tos \
        --email admin@$DOMAIN \
        -d $DOMAIN; then
        
        print_success "Сертификат для $DOMAIN получен успешно"
        
        # Копирование сертификатов в нужные директории
        print_status "Копирование сертификатов..."
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/domain.key
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/domain.crt
    else
        print_error "Ошибка получения сертификата для $DOMAIN"
        print_status "Возможные причины:"
        print_status "1. DNS запись не указывает на этот сервер"
        print_status "2. Порты 80/443 заблокированы файрволом"
        print_status "3. Домен недоступен из интернета"
        exit 1
    fi
    
    # Установка правильных прав доступа
    chmod 600 ssl/*.key
    chmod 644 ssl/*.crt
    
    # Обновление конфигурации Nginx
    print_status "Обновление конфигурации Nginx..."
    sed -i "s/your-domain.com/$DOMAIN/g" nginx.conf
    sed -i "s/terminaus.ru/$DOMAIN/g" nginx.conf
    
    # Запуск nginx обратно
    print_status "Запуск nginx..."
    docker compose up -d nginx-proxy
    
    # Проверка работы nginx
    sleep 5
    if docker compose ps nginx-proxy | grep -q "Up"; then
        print_success "Nginx запущен успешно"
    else
        print_warning "Проблемы с запуском nginx, проверьте логи:"
        docker compose logs nginx-proxy
    fi
    
    print_success "SSL сертификаты Let's Encrypt настроены успешно!"
    print_status "Сертификаты будут автоматически обновляться через cron"
    
    # Настройка автообновления сертификатов
    setup_auto_renewal
}

# Настройка автообновления сертификатов
setup_auto_renewal() {
    print_status "Настройка автообновления сертификатов..."
    
    # Получаем текущую директорию
    CURRENT_DIR=$(pwd)
    
    # Создание скрипта обновления
    cat > /usr/local/bin/renew-certs.sh << EOF
#!/bin/bash
# Переход в директорию проекта
cd $CURRENT_DIR

# Загрузка переменных окружения
if [[ -f ".env" ]]; then
    source .env
    DOMAIN=\$WEBSITE_DOMAIN
else
    echo "Ошибка: файл .env не найден"
    exit 1
fi

# Остановка nginx
docker compose stop nginx-proxy

# Обновление сертификатов
certbot renew --quiet

# Копирование сертификатов
if [[ -f "/etc/letsencrypt/live/\$DOMAIN/fullchain.pem" ]]; then
    cp /etc/letsencrypt/live/\$DOMAIN/fullchain.pem ssl/domain.crt
    cp /etc/letsencrypt/live/\$DOMAIN/privkey.pem ssl/domain.key
    
    # Установка прав
    chmod 600 ssl/*.key
    chmod 644 ssl/*.crt
    
    echo "Сертификаты обновлены успешно"
else
    echo "Ошибка: сертификаты не найдены для домена \$DOMAIN"
fi

# Запуск nginx
docker compose up -d nginx-proxy
EOF
    
    # Делаем скрипт исполняемым
    chmod +x /usr/local/bin/renew-certs.sh
    
    # Добавление задачи в cron (обновление каждый день в 3:00)
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/renew-certs.sh >> /var/log/letsencrypt-renewal.log 2>&1") | crontab -
    
    print_success "Автообновление сертификатов настроено"
    print_status "Сертификаты будут проверяться ежедневно в 3:00"
    print_status "Логи обновления: /var/log/letsencrypt-renewal.log"
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
    
    # Загружаем домен из .env
    if [[ -f ".env" ]]; then
        source .env
        DOMAIN=$WEBSITE_DOMAIN
    fi
    
    echo
    echo "======================================"
    echo -e "${GREEN}Настройка SSL завершена!${NC}"
    echo "======================================"
    echo
    echo "Ваши сайты теперь доступны по HTTPS:"
    echo "- Веб-сайт: https://$DOMAIN"
    echo "- 3X-UI панель: https://$DOMAIN:2053"
    echo
    echo "Проверка сертификатов:"
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        echo "- ✅ Let's Encrypt сертификаты активны"
        echo "- ✅ Автообновление настроено"
        
        # Показать срок действия сертификата
        CERT_EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem | cut -d= -f2)
        echo "- 📅 Срок действия: $CERT_EXPIRY"
    else
        echo "- ❌ Сертификаты не найдены"
    fi
    echo
    echo "Полезные команды:"
    echo "- Проверка сертификатов: certbot certificates"
    echo "- Ручное обновление: /usr/local/bin/renew-certs.sh"
    echo "- Проверка cron: crontab -l"
    echo "- Тест обновления: certbot renew --dry-run"
    echo
}

# Запуск скрипта
main "$@"