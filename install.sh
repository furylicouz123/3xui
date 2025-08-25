#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
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

# Скачивание файлов репозитория
download_repository() {
    print_status "Скачивание файлов репозитория..."
    
    # URL репозитория
    REPO_URL="https://raw.githubusercontent.com/furylicouzzz123/3xui-full/main"
    
    # Список файлов для скачивания
    FILES=(
        "docker-compose.yml"
        "nginx.conf"
        "setup-letsencrypt.sh"
        "Makefile"
        "cleanup.sh"
        "website/index.html"
        "website/script.js"
        "website/assets/main.png"
        ".gitignore"
    )
    
    # Создание необходимых директорий
    mkdir -p website/assets
    
    # Скачивание файлов
    for file in "${FILES[@]}"; do
        print_status "Скачивание $file..."
        if curl -sSL "$REPO_URL/$file" -o "$file"; then
            print_success "$file скачан успешно"
        else
            print_warning "Не удалось скачать $file, продолжаем..."
        fi
    done
    
    # Делаем скрипты исполняемыми
    chmod +x setup-letsencrypt.sh 2>/dev/null || true
    chmod +x cleanup.sh 2>/dev/null || true
    
    # Проверка критически важных файлов
    CRITICAL_FILES=("docker-compose.yml" "nginx.conf")
    for file in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Критически важный файл $file не был скачан!"
            exit 1
        fi
    done
    
    print_success "Файлы репозитория скачаны и проверены"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        exit 1
    fi
}

# Установка Docker и Docker Compose
install_docker() {
    print_status "Установка Docker..."
    
    # Обновление пакетов
    apt update
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Добавление GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Добавление репозитория Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Запуск и автозапуск Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker установлен успешно"
}

# Создание структуры директорий
create_directories() {
    print_status "Создание структуры директорий..."
    
    mkdir -p ssl
    mkdir -p 3x-ui/db
    mkdir -p 3x-ui/cert
    mkdir -p logs/nginx
    mkdir -p logs/xui
    mkdir -p website
    
    # Копирование существующего сайта если он есть в корне
    if [[ -f "index.html" ]] && [[ ! -f "website/index.html" ]]; then
        cp index.html website/
        cp -r assets website/ 2>/dev/null || true
        print_status "Скопирован существующий сайт в директорию website/"
    elif [[ ! -f "website/index.html" ]]; then
        echo "<h1>Welcome to Terminaus.ru</h1>" > website/index.html
        print_status "Создан базовый index.html для веб-сайта"
    fi
    
    print_success "Директории созданы"
}

# Настройка SSL сертификатов через Let's Encrypt
generate_ssl() {
    print_status "Создание SSL сертификатов..."
    
    # Запрос домена у пользователя
    read -p "Введите ваш домен (например, example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        print_error "Домен не может быть пустым!"
        exit 1
    fi
    
    print_status "Используется домен: $DOMAIN"
    print_status "Сайт будет доступен на: https://$DOMAIN:443"
    print_status "3X-UI панель будет доступна на: https://$DOMAIN:2053"
    
    # Сохранение домена в .env файл
    echo "XUI_DOMAIN=$DOMAIN" > .env
    echo "WEBSITE_DOMAIN=$DOMAIN" >> .env
    
    # Проверка наличия nginx.conf (должен быть скачан функцией download_repository)
    if [[ ! -f "nginx.conf" ]]; then
        print_error "Файл nginx.conf не найден. Возможно, произошла ошибка при скачивании файлов репозитория."
        exit 1
    fi
    
    # Обновление конфигурации Nginx
    sed -i "s/your-domain.com/$DOMAIN/g" nginx.conf
    sed -i "s/terminaus.ru/$DOMAIN/g" nginx.conf
    
    # Попытка получить Let's Encrypt сертификаты автоматически
    print_status "Попытка получения Let's Encrypt сертификатов..."
    
    # Установка certbot если не установлен
    if ! command -v certbot &> /dev/null; then
        print_status "Установка certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Создание директории для SSL если не существует
    mkdir -p ssl
    
    # Попытка получить реальные SSL сертификаты
    print_status "Получение SSL сертификата для $DOMAIN..."
    if certbot certonly --standalone --non-interactive --agree-tos \
        --email admin@$DOMAIN \
        -d $DOMAIN 2>/dev/null; then
        
        # Копирование сертификатов Let's Encrypt
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/domain.key
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/domain.crt
        
        # Установка правильных прав доступа
        chmod 600 ssl/*.key
        chmod 644 ssl/*.crt
        
        print_success "Let's Encrypt SSL сертификаты получены и настроены!"
        
        # Настройка автообновления сертификатов
        setup_auto_renewal_cron
    else
        print_warning "Не удалось получить Let's Encrypt сертификаты. Создаю временные..."
        
        # Создание временных SSL сертификатов
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ssl/domain.key \
            -out ssl/domain.crt \
            -subj "/C=RU/ST=Moscow/L=Moscow/O=IT Services/CN=$DOMAIN" 2>/dev/null
        
        print_success "Временные SSL сертификаты созданы"
        print_warning "Для получения настоящих SSL сертификатов запустите: ./setup-letsencrypt.sh"
    fi
}

# Настройка автообновления сертификатов
setup_auto_renewal() {
    print_status "Настройка автообновления сертификатов..."
    
    # Создание скрипта обновления
    cat > /usr/local/bin/renew-certs.sh << 'EOF'
#!/bin/bash
# Скрипт автообновления Let's Encrypt сертификатов

cd $(dirname "$0")/../../load/vpn_page || exit 1

# Загрузка переменных окружения
source .env

# Остановка nginx
docker compose stop nginx-proxy

# Обновление сертификатов
certbot renew --quiet

# Копирование обновленных сертификатов
cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/privkey.pem ssl/domain.key
cp /etc/letsencrypt/live/$WEBSITE_DOMAIN/fullchain.pem ssl/domain.crt

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

# Настройка файрвола
setup_firewall() {
    print_status "Настройка файрвола..."
    
    # Установка ufw если не установлен
    if ! command -v ufw &> /dev/null; then
        apt install -y ufw
    fi
    
    # Базовые правила
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Разрешение SSH
    ufw allow ssh
    
    # Разрешение HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Разрешение 3X-UI панели
    ufw allow 2053/tcp
    
    # Включение файрвола
    ufw --force enable
    
    print_success "Файрвол настроен"
}

# Оптимизация системы для VPN
optimize_system() {
    print_status "Оптимизация системы для VPN..."
    
    # Включение IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    
    # Оптимизация сети
    cat >> /etc/sysctl.conf << EOF
# Оптимизация для VPN
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 65536 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.ipv4.tcp_mtu_probing=1
EOF
    
    # Применение настроек
    sysctl -p
    
    print_success "Система оптимизирована"
}

# Запуск сервисов
start_services() {
    print_status "Запуск сервисов..."
    
    # Проверка наличия необходимых файлов
    if [[ ! -f "docker-compose.yml" ]]; then
        print_error "Файл docker-compose.yml не найден!"
        exit 1
    fi
    
    if [[ ! -f "nginx.conf" ]]; then
        print_error "Файл nginx.conf не найден!"
        exit 1
    fi
    
    # Проверка наличия SSL сертификатов
    if [[ ! -f "ssl/domain.key" ]] || [[ ! -f "ssl/domain.crt" ]]; then
        print_error "SSL сертификаты не найдены!"
        exit 1
    fi
    
    # Запуск Docker Compose
    print_status "Запуск контейнеров..."
    if docker compose up -d; then
        print_status "Контейнеры запущены, ожидание инициализации..."
        
        # Ожидание запуска сервисов
        sleep 15
        
        # Проверка статуса контейнеров
        if docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -q "Up"; then
            print_success "Сервисы запущены успешно"
            
            # Показать статус всех контейнеров
            print_status "Статус контейнеров:"
            docker compose ps
        else
            print_error "Некоторые сервисы не запустились"
            print_status "Логи контейнеров:"
            docker compose logs --tail=20
            
            # Не выходим с ошибкой, просто показываем предупреждение
            print_warning "Проверьте логи выше для диагностики проблем"
        fi
    else
        print_error "Ошибка запуска Docker Compose"
        exit 1
    fi
}

# Вывод информации о доступе
show_access_info() {
    # Загружаем домен из .env файла
    if [[ -f ".env" ]]; then
        source .env
        DOMAIN=$WEBSITE_DOMAIN
    fi
    
    echo
    echo "======================================"
    echo -e "${GREEN}Установка завершена успешно!${NC}"
    echo "======================================"
    echo
    echo "Доступ к веб-сайту:"
    echo "- HTTPS: https://$DOMAIN:443"
    echo "- HTTP: http://$(curl -s ifconfig.me):80"
    echo
    echo "Доступ к 3X-UI панели:"
    echo "- HTTPS: https://$DOMAIN:2053 (рекомендуется)"
    echo "- HTTP: http://$(curl -s ifconfig.me):2053"
    echo
    echo "Данные для входа в 3X-UI:"
    echo "- Логин: admin"
    echo "- Пароль: admin123"
    echo
    echo "SSL сертификаты:"
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        echo "- ✅ Let's Encrypt сертификаты установлены и настроены"
        echo "- ✅ Автообновление сертификатов активно"
    else
        echo "- ⚠️  Используются временные самоподписанные сертификаты"
        echo "- 💡 Для получения настоящих SSL сертификатов запустите: ./setup-letsencrypt.sh"
    fi
    echo
    echo "Следующие шаги:"
    echo "1. Настройте DNS запись для вашего домена:"
    echo "   - $DOMAIN -> $(curl -s ifconfig.me)"
    echo "2. Дождитесь распространения DNS (может занять до 24 часов)"
    echo "3. Проверьте доступность сайтов по HTTPS"
    echo
    echo "Полезные команды:"
    echo "- Просмотр логов: docker compose logs"
    echo "- Остановка: docker compose down"
    echo "- Перезапуск: docker compose restart"
    echo "- Обновление: docker compose pull && docker compose up -d"
    echo "- Проверка сертификатов: certbot certificates"
    echo
}

# Настройка автообновления сертификатов
setup_auto_renewal_cron() {
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
    echo "    Установка Nginx + 3X-UI VPN"
    echo "======================================"
    echo
    
    check_root
    
    # Скачивание файлов репозитория
    download_repository
    
    # Проверка наличия Docker
    if ! command -v docker &> /dev/null; then
        install_docker
    else
        print_success "Docker уже установлен"
    fi
    
    create_directories
    generate_ssl
    setup_firewall
    optimize_system
    start_services
    show_access_info
}

# Запуск скрипта
main "$@"