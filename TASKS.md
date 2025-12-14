# Zadanie Rekrutacyjne - PHP Containerization PoC

## Treść zadania

PoC konteneryzacji dowolnego przykładowego projektu PHP (8.x), który:

### Wymagania podstawowe:
- [x] Wymaga rozszerzeń `pdo-mysql` i `redis`
- [x] Posiada plik `composer.json` z zależnościami kodu PHP
- [x] Może po prostu wyświetlać `phpinfo()`
- [x] Serwer Apache
- [x] Start kontenera powinien ładować plik `/etc/environment` ze zmiennymi środowiskowymi i udostępniać je aplikacji

### Pliki do dostarczenia:
- [x] Dockerfile
- [x] docker-compose.yml
- [x] Reużywalny (jako komenda CLI) przykład budowania obrazu

### Mile widziane:
- [x] Helm i jego budowanie
- [x] Opcja budowania wersji deweloperskiej obrazu np. z rozszerzeniem xdebug dla PHP
- [x] Uwzględnienie Traefik w stworzonych plikach

## Zrealizowane rozwiązanie

### Podstawowe wymagania (100%)

#### 1. PHP 8.3 z rozszerzeniami
- PDO MySQL ✓
- Redis ✓
- Dodatkowe: mbstring, exif, pcntl, bcmath, opcache

#### 2. Composer.json
- Plik: `composer.json`
- Zależności: monolog, phpunit
- Autoloading PSR-4

#### 3. Aplikacja PHP
- Plik: `src/index.php`
- Dashboard z informacjami o środowisku
- Testy połączenia z MySQL i Redis
- phpinfo() dostępne pod `/?phpinfo=1`

#### 4. Serwer Apache
- Apache 2.4
- Moduły: rewrite, headers, expires, deflate
- Security headers
- Health checks

#### 5. Zmienne środowiskowe z /etc/environment
- Plik: `docker/etc/environment`
- Custom entrypoint: `docker/entrypoint.sh`
- Automatyczne ładowanie przy starcie kontenera
- Ekspozycja zmiennych do aplikacji PHP

### Mile widziane (100%)

#### 1. Helm Chart
- Pełny Helm chart w `helm/php-poc/`
- Deployment, Service, Ingress
- ConfigMap dla zmiennych środowiskowych
- HorizontalPodAutoscaler
- ServiceAccount
- Dependencies: MySQL i Redis z Bitnami

#### 2. Wersja deweloperska z Xdebug
- Multi-stage Dockerfile
- Target `development` z Xdebug 3.3
- Docker Compose profile `dev`
- Hot-reload kodu (volume mount)
- Konfiguracja dla VSCode

#### 3. Traefik
- Traefik 3.0 w docker-compose.yml
- Automatic service discovery
- Dashboard na `:8080`
- Routing dla wszystkich serwisów
- Health checks

### Dodatkowe funkcjonalności (bonus)

#### Reużywalne skrypty CLI

**build.sh** - Budowanie obrazów Docker:
```bash
./build.sh --target production --version 1.0.0
./build.sh --target development --version dev --push
```

**helm/build-helm.sh** - Zarządzanie Helm:
```bash
./helm/build-helm.sh --action install
./helm/build-helm.sh --action upgrade
./helm/build-helm.sh --action lint
```

#### Wielostopniowy Dockerfile
- Stage 1: Base (wspólne zależności)
- Stage 2: Composer build
- Stage 3: Production (optymalizowany)
- Stage 4: Development (z Xdebug)

#### Docker Compose Profiles
- Default: Production stack
- `dev`: Development z Xdebug
- `tools`: PHPMyAdmin + Redis Commander

#### Dokumentacja
- Kompletny README.md
- Przykłady użycia
- Troubleshooting
- Production checklist

#### Bezpieczeństwo
- Security headers
- Non-root user (www-data)
- Read-only volumes gdzie możliwe
- Secrets w environment variables
- OPcache w production

#### Monitoring & Observability
- Health checks (Docker & K8s)
- Liveness & Readiness probes
- Logging do stdout/stderr
- Prometheus-ready annotations

## Struktura dostawy

```
g-task/
├── README.md                 ← Główna dokumentacja
├── TASKS.md                  ← Ten plik (opis zadania)
├── Dockerfile                ← Multi-stage Dockerfile
├── docker-compose.yml        ← Orchestration
├── build.sh                  ← CLI build script (executable)
├── composer.json             ← PHP dependencies
├── src/index.php             ← Aplikacja PHP
├── docker/                   ← Konfiguracje
│   ├── entrypoint.sh
│   ├── etc/
│   │   └── environment       ← Zmienne środowiskowe
│   ├── apache/
│   ├── php/
│   └── mysql/
└── helm/                     ← Kubernetes deployment
    ├── build-helm.sh         ← CLI Helm script (executable)
    └── php-poc/              ← Helm chart
```

## Szybki test rozwiązania

### Test 1: Docker Compose (podstawowy)

```bash
# Start wszystkich serwisów
docker-compose up -d

# Sprawdź status
docker-compose ps

# Test aplikacji
curl http://app.localhost

# Test Traefik
open http://traefik.localhost

# Logi
docker-compose logs -f php-app

# Cleanup
docker-compose down -v
```

### Test 2: Budowanie obrazu (CLI script)

```bash
# Production
./build.sh --target production --version 1.0.0

# Development
./build.sh --target development --version dev

# Test uruchomienia
docker run -d -p 8000:80 localhost/php-poc-app:1.0.0
curl http://localhost:8000
```

### Test 3: Development z Xdebug

```bash
# Uruchom dev environment
docker-compose --profile dev up -d

# Sprawdź Xdebug
docker-compose exec php-app-dev php -m | grep xdebug

# Test aplikacji
curl http://dev.localhost
```

### Test 4: Narzędzia (PHPMyAdmin, Redis Commander)

```bash
# Uruchom z narzędziami
docker-compose --profile tools up -d

# PHPMyAdmin
open http://pma.localhost

# Redis Commander
open http://redis.localhost
```

### Test 5: Helm (Kubernetes)

```bash
# Lint chart
./helm/build-helm.sh --action lint

# Dry-run
./helm/build-helm.sh --action template

# Install (wymaga działającego klastra K8s)
./helm/build-helm.sh --action install

# Sprawdź deployment
kubectl get all -l app.kubernetes.io/instance=php-poc
```

## Weryfikacja wymagań

### Checklist wymagań podstawowych:

- [x] **Rozszerzenia PDO-MySQL i Redis**: Sprawdzone w `src/index.php`
- [x] **composer.json z zależnościami**: `composer.json` + `composer.lock`
- [x] **phpinfo()**: Dostępne pod `/?phpinfo=1`
- [x] **Apache**: Apache 2.4 w Dockerfile
- [x] **Ładowanie /etc/environment**: `docker/entrypoint.sh` + test w aplikacji
- [x] **Dockerfile**: Multi-stage, production + development
- [x] **docker-compose.yml**: Pełna konfiguracja z Traefik, MySQL, Redis
- [x] **Reużywalny CLI**: `build.sh` z flagami i pomocą

### Checklist mile widzianych:

- [x] **Helm chart**: Pełny chart w `helm/php-poc/` + build script
- [x] **Development z Xdebug**: Target `development` w Dockerfile + profile w compose
- [x] **Traefik**: Pełna integracja z dashboard i routing

## Sposób dostawy

### Opcja 1: Archiwum

```bash
# Stwórz archiwum
tar -czf php-poc-containerization.tar.gz \
  --exclude='.git' \
  --exclude='vendor' \
  --exclude='*.log' \
  .

# Lub ZIP
zip -r php-poc-containerization.zip . \
  -x "*.git*" "vendor/*" "*.log"
```

### Opcja 2: Repository Git

Repozytorium zawiera wszystkie wymagane pliki i jest gotowe do:
- Sklonowania
- Uruchomienia przez `docker-compose up -d`
- Budowania przez `./build.sh`
- Deploy na K8s przez `./helm/build-helm.sh`

## Czas realizacji

Całkowity czas: ~2-3 godziny na pełne rozwiązanie z dokumentacją

## Uwagi techniczne

1. **Zmienne środowiskowe**: Są ładowane zarówno z `etc/environment` (przez entrypoint) jak i z sekcji `environment` w docker-compose dla wygody developmentu.

2. **Traefik**: Używa labels do auto-discovery serwisów. Wymaga dodania `*.localhost` do `/etc/hosts` lub działa z localhost routing.

3. **Xdebug**: Skonfigurowany dla VSCode na porcie 9003. Wymaga konfiguracji IDE.

4. **Helm dependencies**: MySQL i Redis są dependency charts z Bitnami. Wymagają `helm dependency update`.

5. **Health checks**: Zaimplementowane na wszystkich poziomach (Docker, Compose, K8s).

## Podsumowanie

Rozwiązanie spełnia **100% wymagań podstawowych** i **100% wymagań mile widzianych**, dodatkowo zawiera:
- Production-ready configuration
- Security best practices
- Comprehensive documentation
- Troubleshooting guide
- Multiple deployment options
- Development tools integration

Projekt jest gotowy do użycia zarówno w środowisku deweloperskim jak i produkcyjnym.
