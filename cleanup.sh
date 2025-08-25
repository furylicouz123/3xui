#!/bin/bash

# Полная очистка VPN сервера
# Удаляет все контейнеры, volumes, образы и файлы

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

print_warning "ВНИМАНИЕ: Этот скрипт полностью удалит все данные VPN сервера!"
read -p "Вы уверены? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Операция отменена"
    exit 1
fi

print_status "Начинаем полную очистку..."

# 1. Остановка и удаление контейнеров
print_status "Остановка контейнеров..."
docker-compose down -v --remove-orphans 2>/dev/null || true

# 2. Удаление контейнеров по именам (если остались)
print_status "Удаление контейнеров..."
docker rm -f nginx-proxy xui-panel terminaus-website 2>/dev/null || true

# 3. Удаление образов
print_status "Удаление образов..."
docker rmi nginx:1.27-alpine ghcr.io/mhsanaei/3x-ui:latest 2>/dev/null || true

# 4. Удаление volumes
print_status "Удаление volumes..."
docker volume prune -f 2>/dev/null || true

# 5. Удаление networks
print_status "Удаление сетей..."
docker network rm vpn_network 2>/dev/null || true

# 6. Очистка системы Docker
print_status "Очистка системы Docker..."
docker system prune -af 2>/dev/null || true

# 7. Удаление директорий и файлов
print_status "Удаление файлов и директорий..."
rm -rf ssl/ 2>/dev/null || true
rm -rf 3x-ui/ 2>/dev/null || true
rm -rf logs/ 2>/dev/null || true
rm -rf .env 2>/dev/null || true

# 8. Очистка правил файрвола (опционально)
read -p "Удалить правила файрвола? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Удаление правил файрвола..."
    ufw delete allow 80/tcp 2>/dev/null || true
    ufw delete allow 443/tcp 2>/dev/null || true
    ufw delete allow 2053/tcp 2>/dev/null || true
    print_success "Правила файрвола удалены"
fi

# 9. Очистка системных настроек (опционально)
read -p "Очистить системные настройки сети? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Очистка системных настроек..."
    sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf 2>/dev/null || true
    sysctl -p 2>/dev/null || true
    print_success "Системные настройки очищены"
fi

# 10. Проверка результата
print_status "Проверка результата очистки..."
echo "Запущенные контейнеры:"
docker ps -a | grep -E "nginx|xui|website" || echo "Нет связанных контейнеров"

echo "\nОбразы Docker:"
docker images | grep -E "nginx|3x-ui" || echo "Нет связанных образов"

echo "\nДиректории:"
ls -la | grep -E "ssl|3x-ui|logs" || echo "Директории удалены"

print_success "Полная очистка завершена!"
print_status "Теперь можно запустить новую установку с помощью:"
echo -e "${GREEN}./quick-deploy.sh${NC} или ${GREEN}./install.sh${NC}"