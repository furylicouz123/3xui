#!/bin/bash

# Quick Deploy Script for Production VPN Server
# Fixes all issues and deploys services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "Этот скрипт должен быть запущен от имени root"
   exit 1
fi

# Запрос домена у пользователя
read -p "Введите ваш домен (например, example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    print_error "Домен не может быть пустым!"
    exit 1
fi

print_success "Используется домен: $DOMAIN"

print_status "Начинаем быстрое развертывание VPN сервера..."

# Stop any running containers
print_status "Остановка существующих контейнеров..."
docker-compose down 2>/dev/null || true

# Create directories
print_status "Создание директорий..."
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
    echo "✅ Скопирован существующий сайт в директорию website/"
elif [[ ! -f "website/index.html" ]]; then
    echo "<h1>Welcome to Terminaus.ru</h1>" > website/index.html
    echo "✅ Создан базовый index.html для веб-сайта"
fi

# Generate SSL certificates
print_status "Генерация SSL сертификатов..."

# Ask for XUI domain
read -p "Введите домен для 3X-UI панели (например: panel.yourdomain.com): " XUI_DOMAIN
if [[ -z "$XUI_DOMAIN" ]]; then
    XUI_DOMAIN="localhost"
    print_warning "Используется localhost для 3X-UI"
fi

# Generate SSL certificate for domain
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/domain.key \
    -out ssl/domain.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=VPN Server/OU=IT/CN=$DOMAIN" 2>/dev/null

print_success "SSL сертификаты созданы"

# Set proper permissions
chmod 600 ssl/*.key
chmod 644 ssl/*.crt

# Configure firewall
print_status "Настройка файрвола..."
ufw --force enable 2>/dev/null || true
ufw allow 22/tcp 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 443/tcp 2>/dev/null || true
ufw allow 2053/tcp 2>/dev/null || true
print_success "Файрвол настроен"

# System optimization
print_status "Оптимизация системы..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf 2>/dev/null || true
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf 2>/dev/null || true
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf 2>/dev/null || true
sysctl -p 2>/dev/null || true
print_success "Система оптимизирована"

# Update nginx configuration
print_status "Обновление конфигурации nginx..."
sed -i "s/your-domain.com/$DOMAIN/g" nginx.conf
sed -i "s/terminaus.ru/$DOMAIN/g" nginx.conf
print_success "Конфигурация nginx обновлена"

# Start services
print_status "Запуск сервисов..."
docker-compose up -d

# Wait for services to start
print_status "Ожидание запуска сервисов..."
sleep 10

# Check service status
print_status "Проверка статуса сервисов..."
docker-compose ps

print_success "Развертывание завершено!"

echo -e "\n${GREEN}=== ИНФОРМАЦИЯ О ДОСТУПЕ ===${NC}"
echo -e "${BLUE}Веб-сайт:${NC} https://$DOMAIN:443"
echo -e "${BLUE}3X-UI панель:${NC} https://$DOMAIN:2053"
echo -e "${BLUE}Логин 3X-UI:${NC} admin"
echo -e "${BLUE}Пароль 3X-UI:${NC} admin123"
echo -e "\n${YELLOW}Не забудьте настроить DNS запись для домена $DOMAIN!${NC}"
echo -e "${YELLOW}Для продакшена рекомендуется использовать Let's Encrypt сертификаты.${NC}"