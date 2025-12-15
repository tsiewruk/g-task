# PHP Containerization PoC

Proof of Concept konteneryzacji aplikacji PHP 8.x z Apache, MySQL, Redis i Traefik.

## Spis treści

- [Wymagania](#wymagania)
- [Funkcjonalności](#funkcjonalności)
- [Struktura projektu](#struktura-projektu)
- [Szybki start](#szybki-start)
- [Budowanie obrazu Docker](#budowanie-obrazu-docker)
- [Docker Compose](#docker-compose)
- [Testy jednostkowe](#testy-jednostkowe)
- [Środowiska](#środowiska)
- [Zmienne środowiskowe](#zmienne-środowiskowe)
- [Endpointy](#endpointy)

## Wymagania

### Minimalne wymagania:
- Docker 24.0+
- Docker Compose 2.20+

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
- ✅ Opcja budowania wersji deweloperskiej z Xdebug
- ✅ Traefik jako reverse proxy
- ✅ Health checks
- ✅ Production-ready configuration (OPcache, security headers)

### Dodatkowe funkcjonalności:
- ✅ Multi-stage Dockerfile (production & development)
- ✅ Automatyczne czekanie na MySQL i Redis (entrypoint)
- ✅ Comprehensive logging
- ✅ Security best practices
- ✅ Persistentne wolumeny dla danych

## Struktura projektu

```
.
├── README.md                      # Dokumentacja
├── Dockerfile                     # Multi-stage Dockerfile
├── docker-compose.yml             # Orchestracja kontenerów
├── composer.json                  # Zależności PHP
├── composer.lock                  # Wersje zależności
│
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml               # Główny CI/CD pipeline
│   │   ├── manual-deploy.yml       # Ręczne deployment
│   │   └── test-only.yml           # Szybkie testy
│
│
├── src/
│   ├── index.php                  # Główna aplikacja PHP
│   └── Helper.php                 # Klasa pomocnicza z funkcjami utility
│
├── tests/
│   └── Unit/
│       ├── HelperTest.php         # Testy jednostkowe dla Helper
│       └── EnvironmentTest.php    # Testy walidacji środowiska
│
├── phpunit.xml                    # Konfiguracja PHPUnit
│
└── docker/
    ├── entrypoint.sh              # Entrypoint ładujący /etc/environment
    ├── etc/
    │   └── environment            # Zmienne środowiskowe
    ├── apache/
    │   ├── apache2.conf           # Konfiguracja Apache
    │   └── security.conf          # Security headers
    ├── php/
    │   ├── php.ini                # PHP config (production)
    │   ├── php-dev.ini            # PHP config (development)
    │   ├── opcache.ini            # OPcache config
    │   └── xdebug.ini             # Xdebug config (dev only)
    └── mysql/
        └── init.sql               # Inicjalizacja bazy danych
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

### 3. Zatrzymanie

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

## Testy jednostkowe

Projekt zawiera testy jednostkowe PHPUnit dla walidacji funkcjonalności core.

### Uruchamianie testów

```bash
# Uruchom wszystkie testy jednostkowe
make test-unit

# Uruchom testy z code coverage
make test-unit-coverage

# Bezpośrednio przez Docker
docker run --rm -v "$(pwd)":/app -w /app composer:2.7 exec phpunit
```

### Zawarte zestawy testów

1. **HelperTest** (`tests/Unit/HelperTest.php`) - 6 testów
   - Testowanie formatowania logów
   - Walidacja timestampów
   - Testowanie funkcji maskowania danych wrażliwych

2. **EnvironmentTest** (`tests/Unit/EnvironmentTest.php`) - 6 testów
   - Walidacja zmiennych środowiskowych
   - Wykrywanie brakujących konfiguracji
   - Testowanie edge cases

### Statystyki testów

```
PHPUnit 11.5.46
Runtime: PHP 8.3
OK (12 tests, 36 assertions)
```

### Struktura testów

```
tests/
└── Unit/
    ├── HelperTest.php         # Testy logowania i maskowania
    └── EnvironmentTest.php    # Testy walidacji środowiska
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


