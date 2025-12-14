# PHP Containerization PoC

Proof of Concept konteneryzacji aplikacji PHP 8.x z Apache, MySQL, Redis i Traefik.

## Spis treści

- [Wymagania](#wymagania)
- [Funkcjonalności](#funkcjonalności)
- [Struktura projektu](#struktura-projektu)
- [Szybki start](#szybki-start)
- [Budowanie obrazu Docker](#budowanie-obrazu-docker)
- [Docker Compose](#docker-compose)
- [Kubernetes & Helm](#kubernetes--helm)
- [Środowiska](#środowiska)
- [Zmienne środowiskowe](#zmienne-środowiskowe)
- [Endpointy](#endpointy)
- [Rozwiązywanie problemów](#rozwiązywanie-problemów)

## Wymagania

### Minimalne wymagania:
- Docker 24.0+
- Docker Compose 2.20+

### Opcjonalne (dla Kubernetes):
- kubectl 1.28+
- Helm 3.12+
- Kubernetes cluster (minikube, k3s, lub produkcyjny)

## Funkcjonalności

### Podstawowe wymagania (zrealizowane):
- ✅ PHP 8.3 z rozszerzeniami `pdo-mysql` i `redis`
- ✅ Serwer Apache 2.4
- ✅ Plik `composer.json` z zależnościami
- ✅ Aplikacja wyświetlająca `phpinfo()`
- ✅ Ładowanie zmiennych z `/etc/environment`
- ✅ Dockerfile z multi-stage build
- ✅ docker-compose.yml
- ✅ Reużywalny skrypt CLI do budowania (`build.sh`)

### Mile widziane (zrealizowane):
- ✅ Helm chart z pełną konfiguracją
- ✅ Opcja budowania wersji deweloperskiej z Xdebug
- ✅ Traefik jako reverse proxy
- ✅ Health checks
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Production-ready configuration (OPcache, security headers)

### Dodatkowe funkcjonalności:
- ✅ Multi-stage Dockerfile (production & development)
- ✅ Automatyczne czekanie na MySQL i Redis (entrypoint)
- ✅ PHPMyAdmin i Redis Commander (opcjonalne narzędzia)
- ✅ Comprehensive logging
- ✅ Security best practices
- ✅ Persistentne wolumeny dla danych

## Struktura projektu

```
.
├── README.md                      # Dokumentacja
├── TASKS.md                       # Opis zadania rekrutacyjnego
├── Dockerfile                     # Multi-stage Dockerfile
├── docker-compose.yml             # Orchestracja kontenerów
├── composer.json                  # Zależności PHP
├── composer.lock                  # Wersje zależności
├── build.sh                       # Skrypt CLI do budowania obrazów
│
├── src/
│   └── index.php                  # Główna aplikacja PHP
│
├── docker/
│   ├── entrypoint.sh              # Entrypoint ładujący /etc/environment
│   ├── etc/
│   │   └── environment            # Zmienne środowiskowe
│   ├── apache/
│   │   ├── apache2.conf           # Konfiguracja Apache
│   │   └── security.conf          # Security headers
│   ├── php/
│   │   ├── php.ini                # PHP config (production)
│   │   ├── php-dev.ini            # PHP config (development)
│   │   ├── opcache.ini            # OPcache config
│   │   └── xdebug.ini             # Xdebug config (dev only)
│   └── mysql/
│       └── init.sql               # Inicjalizacja bazy danych
│
└── helm/
    ├── build-helm.sh              # Skrypt CLI do Helm
    └── php-poc/
        ├── Chart.yaml             # Definicja Helm chart
        ├── values.yaml            # Wartości domyślne
        └── templates/             # Kubernetes manifests
            ├── deployment.yaml
            ├── service.yaml
            ├── ingress.yaml
            ├── configmap.yaml
            ├── serviceaccount.yaml
            ├── hpa.yaml
            └── _helpers.tpl
```

## Szybki start

### 1. Uruchomienie z Docker Compose (najprostsze)

```bash
# Uruchom wszystkie serwisy (production)
docker-compose up -d

# Sprawdź status
docker-compose ps

# Zobacz logi
docker-compose logs -f php-app

# Otwórz w przeglądarce
open http://app.localhost
```

### 2. Dostęp do aplikacji i narzędzi

| Serwis | URL | Opis |
|--------|-----|------|
| Aplikacja PHP | http://app.localhost | Główna aplikacja |
| Traefik Dashboard | http://traefik.localhost lub http://localhost:8080 | Panel Traefik |
| PHPMyAdmin | http://pma.localhost | Zarządzanie MySQL (profil `tools`) |
| Redis Commander | http://redis.localhost | Zarządzanie Redis (profil `tools`) |

### 3. Uruchomienie narzędzi (opcjonalnie)

```bash
# Uruchom z PHPMyAdmin i Redis Commander
docker-compose --profile tools up -d
```

### 4. Zatrzymanie

```bash
# Zatrzymaj wszystkie kontenery
docker-compose down

# Zatrzymaj i usuń wolumeny
docker-compose down -v
```

## Budowanie obrazu Docker

### Użycie skryptu build.sh (rekomendowane)

Skrypt `build.sh` to reużywalne narzędzie CLI do budowania obrazów:

```bash
# Wyświetl pomoc
./build.sh --help

# Zbuduj obraz production
./build.sh --target production --version 1.0.0

# Zbuduj obraz development z Xdebug
./build.sh --target development --version dev

# Zbuduj i wypchnij do registry
./build.sh \
  --target production \
  --version 1.0.0 \
  --registry docker.io/myuser \
  --push

# Clean build (bez cache)
./build.sh --target production --clean

# Zmiana nazwy obrazu
./build.sh \
  --target production \
  --version 1.0.0 \
  --name my-php-app
```

### Ręczne budowanie (alternatywa)

```bash
# Production
docker build --target production -t php-poc-app:latest .

# Development
docker build --target development -t php-poc-app:dev .

# Uruchom kontener
docker run -d -p 8000:80 --name php-app php-poc-app:latest
```

## Docker Compose

### Profile dostępne w docker-compose.yml

1. **Default** (bez profilu) - uruchamia:
   - Traefik
   - PHP App (production)
   - MySQL
   - Redis

2. **dev** - wersja deweloperska z Xdebug:
```bash
docker-compose --profile dev up -d
```

3. **tools** - narzędzia developerskie:
```bash
docker-compose --profile tools up -d
```

### Konfiguracja środowiskowa

Edytuj `docker/etc/environment` aby zmienić zmienne:

```bash
# docker/etc/environment
APP_ENV=production
APP_NAME="PHP PoC Application"
MYSQL_HOST=mysql
MYSQL_DATABASE=app_db
REDIS_HOST=redis
# ... inne zmienne
```

### Przydatne komendy

```bash
# Restart pojedynczego serwisu
docker-compose restart php-app

# Zobacz logi konkretnego serwisu
docker-compose logs -f mysql

# Wykonaj komendę w kontenerze
docker-compose exec php-app bash

# Sprawdź użycie zasobów
docker stats

# Przeskaluj aplikację (tylko bez Traefik routingu)
docker-compose up -d --scale php-app=3
```

## Kubernetes & Helm

### Instalacja z Helm

Użyj skryptu `build-helm.sh`:

```bash
cd helm

# Wyświetl pomoc
./build-helm.sh --help

# Sprawdź poprawność chart
./build-helm.sh --action lint

# Wygeneruj manifesty (dry-run)
./build-helm.sh --action template

# Zainstaluj aplikację
./build-helm.sh --action install

# Zainstaluj z custom values
./build-helm.sh \
  --action install \
  --values custom-values.yaml \
  --namespace production

# Upgrade istniejącej instalacji
./build-helm.sh --action upgrade

# Odinstaluj
./build-helm.sh --action uninstall
```

### Ręczna instalacja Helm (alternatywa)

```bash
# Dodaj Bitnami repo (dla MySQL i Redis)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Update dependencies
cd helm/php-poc
helm dependency update

# Zainstaluj
helm install php-poc . \
  --namespace default \
  --create-namespace

# Sprawdź status
helm status php-poc

# Zobacz deployed resources
kubectl get all -l app.kubernetes.io/instance=php-poc
```

### Konfiguracja Helm

Edytuj `helm/php-poc/values.yaml` lub stwórz własny plik values:

```yaml
# custom-values.yaml
replicaCount: 3

image:
  repository: myregistry/php-poc-app
  tag: "1.0.0"

ingress:
  enabled: true
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

```bash
helm upgrade php-poc . -f custom-values.yaml
```

### Autoscaling

HPA jest domyślnie włączony. Sprawdź:

```bash
kubectl get hpa

# Przykładowe wyjście:
# NAME      REFERENCE          TARGETS         MINPODS   MAXPODS   REPLICAS
# php-poc   Deployment/php-poc   15%/70%        2         10        2
```

## Środowiska

### Production (domyślne)

- OPcache włączony
- Display errors wyłączone
- Optymalizacje performance
- Security headers
- Bez Xdebug

```bash
# Docker Compose
docker-compose up -d

# Helm
./helm/build-helm.sh --action install
```

### Development (z Xdebug)

- Xdebug 3.3 włączony
- Display errors włączone
- Hot-reload kodu (volume mount)
- Extended memory limits
- Verbose logging

```bash
# Docker Compose
docker-compose --profile dev up -d

# Dostęp na http://dev.localhost

# Konfiguracja Xdebug w IDE:
# - Host: localhost
# - Port: 9003
# - IDE key: VSCODE
```

### Konfiguracja VSCode dla Xdebug

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html/src": "${workspaceFolder}/src"
      }
    }
  ]
}
```

## Zmienne środowiskowe

Zmienne ładowane z `/etc/environment` przez entrypoint:

| Zmienna | Wartość domyślna | Opis |
|---------|------------------|------|
| APP_ENV | production | Środowisko (production/development) |
| APP_NAME | PHP PoC Application | Nazwa aplikacji |
| APP_DEBUG | false | Debug mode |
| MYSQL_HOST | mysql | Host MySQL |
| MYSQL_PORT | 3306 | Port MySQL |
| MYSQL_DATABASE | app_db | Nazwa bazy danych |
| MYSQL_USER | app_user | Użytkownik MySQL |
| MYSQL_PASSWORD | app_password | Hasło MySQL |
| REDIS_HOST | redis | Host Redis |
| REDIS_PORT | 6379 | Port Redis |

## Endpointy

### Główna aplikacja

- `GET /` - Dashboard z informacjami o środowisku
- `GET /?phpinfo=1` - Pełne phpinfo()

### Health checks

- Apache health check (Docker): `curl http://localhost/`
- Kubernetes liveness: `GET /`
- Kubernetes readiness: `GET /`

## Rozwiązywanie problemów

### Kontenery nie startują

```bash
# Sprawdź logi
docker-compose logs

# Sprawdź status
docker-compose ps

# Restart serwisów
docker-compose restart
```

### MySQL connection refused

Problem: Aplikacja startuje przed MySQL.

Rozwiązanie: Entrypoint czeka na MySQL automatycznie (health check).

```bash
# Sprawdź health MySQL
docker-compose ps mysql

# Zobacz logi MySQL
docker-compose logs mysql
```

### Redis connection issues

```bash
# Sprawdź status Redis
docker-compose exec redis redis-cli ping

# Powinno zwrócić: PONG
```

### Traefik nie routuje ruchu

```bash
# Sprawdź dashboard Traefik
open http://localhost:8080

# Sprawdź czy kontenery mają label traefik.enable=true
docker inspect php_poc_app | grep traefik.enable

# Dodaj wpis do /etc/hosts jeśli potrzebne
echo "127.0.0.1 app.localhost" | sudo tee -a /etc/hosts
```

### Xdebug nie działa (dev)

```bash
# Sprawdź czy Xdebug jest załadowany
docker-compose exec php-app-dev php -m | grep xdebug

# Zobacz konfigurację Xdebug
docker-compose exec php-app-dev php -i | grep xdebug

# Sprawdź logi Xdebug
docker-compose exec php-app-dev tail -f /var/log/apache2/xdebug.log
```

### Permission issues

```bash
# Fix permissions
docker-compose exec php-app chown -R www-data:www-data /var/www/html
```

## Produkcja

### Checklist przed wdrożeniem:

- [ ] Zmień hasła w `docker-compose.yml` i `etc/environment`
- [ ] Skonfiguruj SSL/TLS (Let's Encrypt z Traefik)
- [ ] Włącz backupy MySQL (persistent volumes + cron)
- [ ] Skonfiguruj monitoring (Prometheus + Grafana)
- [ ] Przejrzyj resource limits w values.yaml
- [ ] Włącz network policies w Kubernetes
- [ ] Skonfiguruj log aggregation (ELK/Loki)

### Bezpieczeństwo:

- Security headers są włączone (X-Frame-Options, X-Content-Type-Options)
- OPcache włączony w production
- PHP expose_php wyłączone
- Apache ServerTokens ustawione na Prod
- Read-only filesystem dla wrażliwych katalogów

## Technologie

- **PHP**: 8.3 (Apache)
- **Web Server**: Apache 2.4
- **Database**: MySQL 8.0
- **Cache**: Redis 7
- **Reverse Proxy**: Traefik 3.0
- **Orchestration**: Docker Compose / Kubernetes
- **Package Manager**: Composer 2.7
- **Deployment**: Helm 3

## Licencja

PoC dla celów rekrutacyjnych.

## Kontakt

W razie pytań lub problemów, otwórz issue w repozytorium.

---

**Stworzone z wykorzystaniem Claude Code** 🚀
