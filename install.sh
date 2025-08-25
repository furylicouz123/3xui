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
    
    # Создание SSL сертификата для домена
    print_status "Создание SSL сертификата для $DOMAIN..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/domain.key \
        -out ssl/domain.crt \
        -subj "/C=RU/ST=Moscow/L=Moscow/O=IT Services/CN=$DOMAIN" 2>/dev/null
    
    # Обновление конфигурации Nginx
    sed -i "s/your-domain.com/$DOMAIN/g" nginx.conf
    sed -i "s/terminaus.ru/$DOMAIN/g" nginx.conf
    
    print_success "Временные SSL сертификаты созданы"
    print_warning "После установки запустите: ./setup-letsencrypt.sh для получения настоящих SSL сертификатов"
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
    
    # Запуск Docker Compose
    docker compose up -d
    
    # Ожидание запуска сервисов
    sleep 10
    
    # Проверка статуса
    if docker compose ps | grep -q "Up"; then
        print_success "Сервисы запущены успешно"
    else
        print_error "Ошибка запуска сервисов"
        docker compose logs
        exit 1
    fi
}

# Вывод информации о доступе
show_access_info() {
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
    echo "Следующие шаги:"
    echo "1. Настройте DNS запись для вашего домена:"
    echo "   - $DOMAIN -> $(curl -s ifconfig.me)"
    echo "2. Для продакшена рекомендуется настроить Let's Encrypt SSL"
    echo
    echo "Полезные команды:"
    echo "- Просмотр логов: docker compose logs"
    echo "- Остановка: docker compose down"
    echo "- Перезапуск: docker compose restart"
    echo "- Обновление: docker compose pull && docker compose up -d"
    echo
}

# Основная функция
main() {
    clear
    echo "======================================"
    echo "    Установка Nginx + 3X-UI VPN"
    echo "======================================"
    echo
    
    check_root
    
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