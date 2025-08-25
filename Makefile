# Makefile для управления VPN сервером (Nginx + 3X-UI)

# Переменные
COMPOSE_FILE := docker-compose.yml
PROJECT_NAME := vpn-server
BACKUP_DIR := ./backups
DATE := $(shell date +%Y%m%d_%H%M%S)

# Цвета для вывода
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

.PHONY: help install start stop restart status logs clean backup restore update ssl-gen cleanup

# Помощь
help:
	@echo "$(GREEN)Доступные команды:$(RESET)"
	@echo "  $(YELLOW)install$(RESET)     - Полная установка и настройка"
	@echo "  $(YELLOW)start$(RESET)       - Запуск сервисов"
	@echo "  $(YELLOW)stop$(RESET)        - Остановка сервисов"
	@echo "  $(YELLOW)restart$(RESET)     - Перезапуск сервисов"
	@echo "  $(YELLOW)status$(RESET)      - Статус сервисов"
	@echo "  $(YELLOW)logs$(RESET)        - Просмотр логов"
	@echo "  $(YELLOW)logs-f$(RESET)      - Просмотр логов в реальном времени"
	@echo "  $(YELLOW)backup$(RESET)      - Создание резервной копии"
	@echo "  $(YELLOW)restore$(RESET)     - Восстановление из резервной копии"
	@echo "  $(YELLOW)update$(RESET)      - Обновление образов"
	@echo "  $(YELLOW)ssl-gen$(RESET)     - Генерация SSL сертификатов"
	@echo "  $(YELLOW)clean$(RESET)       - Очистка системы"
	@echo "  $(YELLOW)shell-nginx$(RESET) - Подключение к контейнеру Nginx"
	@echo "  $(YELLOW)shell-xui$(RESET)   - Подключение к контейнеру 3X-UI"

# Полная установка
install:
	@echo "$(GREEN)Начинаем установку VPN сервера...$(RESET)"
	@chmod +x install.sh
	@sudo ./install.sh

# Создание необходимых директорий
setup-dirs:
	@echo "$(GREEN)Создание директорий...$(RESET)"
	@mkdir -p ssl nginx/conf.d 3x-ui/db 3x-ui/cert logs/nginx logs/xui $(BACKUP_DIR)

# Копирование конфигурации
setup-config:
	@echo "$(GREEN)Настройка конфигурации...$(RESET)"
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@if [ ! -f nginx/nginx.conf ]; then cp nginx.conf nginx/nginx.conf; fi

# Генерация SSL сертификатов
ssl-gen:
	@echo "$(GREEN)Генерация SSL сертификатов...$(RESET)"
	@mkdir -p ssl
	@read -p "Введите домен для 3X-UI панели: " xui_domain; \
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/key.pem \
		-out ssl/cert.pem \
		-subj "/C=RU/ST=Moscow/L=Moscow/O=VPN-Server/CN=$$xui_domain"
	@echo "$(GREEN)Генерация сертификата для terminaus.ru...$(RESET)"
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/terminaus.ru.key \
		-out ssl/terminaus.ru.crt \
		-subj "/C=RU/ST=Moscow/L=Moscow/O=Terminaus/CN=terminaus.ru"
	@echo "$(GREEN)SSL сертификаты созданы для обоих доменов$(RESET)"

# Запуск сервисов
start: setup-dirs setup-config
	@echo "$(GREEN)Запуск сервисов...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d
	@echo "$(GREEN)Сервисы запущены$(RESET)"

# Остановка сервисов
stop:
	@echo "$(YELLOW)Остановка сервисов...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) down
	@echo "$(GREEN)Сервисы остановлены$(RESET)"

# Перезапуск сервисов
restart:
	@echo "$(YELLOW)Перезапуск сервисов...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) restart
	@echo "$(GREEN)Сервисы перезапущены$(RESET)"

# Статус сервисов
status:
	@echo "$(GREEN)Статус сервисов:$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps
	@echo ""
	@echo "$(GREEN)Использование ресурсов:$(RESET)"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Просмотр логов
logs:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs --tail=100

# Просмотр логов в реальном времени
logs-f:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs -f

# Логи Nginx
logs-nginx:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs nginx --tail=100

# Логи 3X-UI
logs-xui:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs xui --tail=100

# Создание резервной копии
backup:
	@echo "$(GREEN)Создание резервной копии...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec -T xui tar -czf /tmp/xui-backup.tar.gz /etc/x-ui
	@docker cp $$(docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps -q xui):/tmp/xui-backup.tar.gz $(BACKUP_DIR)/xui-backup-$(DATE).tar.gz
	@tar -czf $(BACKUP_DIR)/config-backup-$(DATE).tar.gz ssl/ nginx/ .env docker-compose.yml
	@echo "$(GREEN)Резервная копия создана: $(BACKUP_DIR)/xui-backup-$(DATE).tar.gz$(RESET)"

# Восстановление из резервной копии
restore:
	@echo "$(YELLOW)Доступные резервные копии:$(RESET)"
	@ls -la $(BACKUP_DIR)/*xui-backup*.tar.gz 2>/dev/null || echo "Резервные копии не найдены"
	@read -p "Введите имя файла резервной копии: " backup_file; \
	if [ -f "$(BACKUP_DIR)/$$backup_file" ]; then \
		docker cp $(BACKUP_DIR)/$$backup_file $$(docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps -q xui):/tmp/; \
		docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec xui tar -xzf /tmp/$$backup_file -C /; \
		docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) restart xui; \
		echo "$(GREEN)Восстановление завершено$(RESET)"; \
	else \
		echo "$(RED)Файл не найден$(RESET)"; \
	fi

# Обновление образов
update:
	@echo "$(GREEN)Обновление образов...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) pull
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d
	@echo "$(GREEN)Обновление завершено$(RESET)"

# Подключение к контейнеру Nginx
shell-nginx:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec nginx /bin/sh

# Подключение к контейнеру 3X-UI
shell-xui:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec xui /bin/bash

# Подключение к контейнеру веб-сайта
shell-website:
	@echo "$(GREEN)Подключение к контейнеру веб-сайта...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec website /bin/sh

# Обновление файлов веб-сайта
website-update:
	@echo "$(GREEN)Обновление файлов веб-сайта...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) restart website
	@echo "$(GREEN)Веб-сайт обновлен$(RESET)"

# Полная очистка установки
cleanup:
	@echo "$(RED)ВНИМАНИЕ: Полная очистка всех данных!$(RESET)"
	@chmod +x cleanup.sh
	@./cleanup.sh

# Мониторинг ресурсов
monitor:
	@watch -n 2 'docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"'

# Проверка конфигурации Nginx
nginx-test:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec nginx nginx -t

# Перезагрузка конфигурации Nginx
nginx-reload:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec nginx nginx -s reload
	@echo "$(GREEN)Конфигурация Nginx перезагружена$(RESET)"

# Очистка системы
clean:
	@echo "$(YELLOW)Очистка неиспользуемых ресурсов...$(RESET)"
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)Очистка завершена$(RESET)"

# Полная очистка (ОСТОРОЖНО!)
clean-all:
	@echo "$(RED)ВНИМАНИЕ: Это удалит ВСЕ данные!$(RESET)"
	@read -p "Вы уверены? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) down -v; \
		docker system prune -af; \
		sudo rm -rf ssl/ nginx/ 3x-ui/ logs/ $(BACKUP_DIR)/; \
		echo "$(GREEN)Полная очистка завершена$(RESET)"; \
	else \
		echo "$(YELLOW)Операция отменена$(RESET)"; \
	fi

# Информация о системе
info:
	@echo "$(GREEN)Информация о системе:$(RESET)"
	@echo "Docker версия: $$(docker --version)"
	@echo "Docker Compose версия: $$(docker compose version)"
	@echo "Проект: $(PROJECT_NAME)"
	@echo "Файл конфигурации: $(COMPOSE_FILE)"
	@echo "Директория резервных копий: $(BACKUP_DIR)"
	@echo ""
	@echo "$(GREEN)Сетевая информация:$(RESET)"
	@echo "Внешний IP: $$(curl -s ifconfig.me 2>/dev/null || echo 'Недоступен')"
	@echo "Открытые порты: $$(ss -tlnp | grep -E ':(80|443|2053)' | awk '{print $$4}' | cut -d: -f2 | sort -u | tr '\n' ' ')"

# По умолчанию показываем help
default: help