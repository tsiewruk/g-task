# Makefile dla PHP PoC Containerization
# Ułatwia uruchamianie najczęstszych komend

.PHONY: help build up down logs clean test dev prod tools

# Kolory
BLUE := \033[0;34m
GREEN := \033[0;32m
NC := \033[0m

help: ## Wyświetl pomoc
	@echo "$(BLUE)==========================================\n"
	@echo "PHP PoC Containerization - Makefile\n"
	@echo "==========================================$(NC)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

build: ## Zbuduj obraz production (./build.sh)
	@echo "$(BLUE)Building production image...$(NC)"
	./build.sh --target production --version latest

build-dev: ## Zbuduj obraz development (./build.sh)
	@echo "$(BLUE)Building development image...$(NC)"
	./build.sh --target development --version dev

up: ## Uruchom stack production (docker-compose up)
	@echo "$(BLUE)Starting production stack...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Application running at http://app.localhost$(NC)"
	@echo "$(GREEN)✓ Traefik dashboard at http://traefik.localhost$(NC)"

dev: ## Uruchom stack development z Xdebug
	@echo "$(BLUE)Starting development stack...$(NC)"
	docker-compose --profile dev up -d
	@echo "$(GREEN)✓ Dev application running at http://dev.localhost$(NC)"

tools: ## Uruchom z PHPMyAdmin i Redis Commander
	@echo "$(BLUE)Starting with development tools...$(NC)"
	docker-compose --profile tools up -d
	@echo "$(GREEN)✓ PHPMyAdmin at http://pma.localhost$(NC)"
	@echo "$(GREEN)✓ Redis Commander at http://redis.localhost$(NC)"

down: ## Zatrzymaj wszystkie kontenery
	@echo "$(BLUE)Stopping containers...$(NC)"
	docker-compose --profile dev --profile tools down

restart: ## Restart aplikacji
	@echo "$(BLUE)Restarting application...$(NC)"
	docker-compose restart php-app

logs: ## Zobacz logi aplikacji
	docker-compose logs -f php-app

logs-all: ## Zobacz wszystkie logi
	docker-compose logs -f

ps: ## Lista uruchomionych kontenerów
	docker-compose ps

clean: ## Usuń kontenery i wolumeny
	@echo "$(BLUE)Cleaning up...$(NC)"
	docker-compose --profile dev --profile tools down -v
	docker system prune -f

clean-all: ## Usuń wszystko włącznie z obrazami
	@echo "$(BLUE)Deep cleaning...$(NC)"
	docker-compose --profile dev --profile tools down -v --rmi all
	docker system prune -af

test: ## Test połączenia z aplikacją
	@echo "$(BLUE)Testing application...$(NC)"
	@curl -s http://app.localhost > /dev/null && echo "$(GREEN)✓ Application is responding$(NC)" || echo "$(RED)✗ Application is not responding$(NC)"

shell: ## Połącz się z kontenerem PHP (bash)
	docker-compose exec php-app bash

mysql: ## Połącz się z MySQL CLI
	docker-compose exec mysql mysql -u app_user -papp_password app_db

redis: ## Połącz się z Redis CLI
	docker-compose exec redis redis-cli

# Helm commands
helm-lint: ## Lint Helm chart
	./helm/build-helm.sh --action lint

helm-template: ## Generuj Helm templates
	./helm/build-helm.sh --action template

helm-install: ## Zainstaluj Helm chart
	./helm/build-helm.sh --action install

helm-upgrade: ## Upgrade Helm release
	./helm/build-helm.sh --action upgrade

helm-uninstall: ## Odinstaluj Helm release
	./helm/build-helm.sh --action uninstall

# Development helpers
composer-install: ## Zainstaluj Composer dependencies w kontenerze
	docker-compose exec php-app composer install

composer-update: ## Update Composer dependencies
	docker-compose exec php-app composer update

watch: ## Obserwuj logi w trybie follow
	docker-compose logs -f --tail=100

stats: ## Statystyki użycia zasobów
	docker stats

# Info commands
info: ## Wyświetl informacje o stacku
	@echo "$(BLUE)==========================================\n"
	@echo "PHP PoC Containerization - Stack Info\n"
	@echo "==========================================$(NC)\n"
	@echo "$(GREEN)URLs:$(NC)"
	@echo "  Application:    http://app.localhost"
	@echo "  Dev App:        http://dev.localhost"
	@echo "  Traefik:        http://traefik.localhost"
	@echo "  PHPMyAdmin:     http://pma.localhost"
	@echo "  Redis UI:       http://redis.localhost"
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(GREEN)Images:$(NC)"
	@docker images | grep php-poc

archive: ## Stwórz archiwum projektu (tar.gz)
	@echo "$(BLUE)Creating archive...$(NC)"
	tar -czf php-poc-containerization.tar.gz \
		--exclude='.git' \
		--exclude='vendor' \
		--exclude='*.log' \
		--exclude='helm/php-poc/charts' \
		.
	@echo "$(GREEN)✓ Archive created: php-poc-containerization.tar.gz$(NC)"

zip: ## Stwórz archiwum projektu (zip)
	@echo "$(BLUE)Creating ZIP archive...$(NC)"
	zip -r php-poc-containerization.zip . \
		-x "*.git*" "vendor/*" "*.log" "helm/php-poc/charts/*"
	@echo "$(GREEN)✓ Archive created: php-poc-containerization.zip$(NC)"
