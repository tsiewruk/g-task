# Quick Start Guide - PHP PoC

Najszybsza ścieżka do uruchomienia projektu.

## Wymagania

- Docker 24.0+
- Docker Compose 2.20+

## Uruchomienie w 30 sekund

```bash
# 1. Sklonuj/rozpakuj projekt
cd g-task

# 2. Uruchom stack
docker-compose up -d

# 3. Poczekaj ~30 sekund na inicjalizację MySQL

# 4. Otwórz w przeglądarce
open http://app.localhost
```

## Dostępne URL-e

| Serwis | URL |
|--------|-----|
| Aplikacja PHP | http://app.localhost |
| phpinfo() | http://app.localhost/?phpinfo=1 |
| Traefik Dashboard | http://localhost:8080 lub http://traefik.localhost |

## Przydatne komendy

```bash
# Zobacz logi
docker-compose logs -f

# Status kontenerów
docker-compose ps

# Zatrzymaj
docker-compose down

# Zatrzymaj + usuń dane
docker-compose down -v

# Restart pojedynczego serwisu
docker-compose restart php-app
```

## Użycie Makefile (opcjonalnie)

Jeśli wolisz prostsze komendy:

```bash
# Zobacz wszystkie dostępne komendy
make help

# Uruchom
make up

# Zobacz logi
make logs

# Zatrzymaj
make down

# Wyczyść wszystko
make clean
```

## Development z Xdebug

```bash
# Uruchom wersję deweloperską
docker-compose --profile dev up -d

# Dostęp
open http://dev.localhost

# Lub z Makefile
make dev
```

## Narzędzia developerskie

```bash
# Uruchom z PHPMyAdmin i Redis Commander
docker-compose --profile tools up -d

# PHPMyAdmin: http://pma.localhost
# Login: app_user / app_password

# Redis Commander: http://redis.localhost

# Lub z Makefile
make tools
```

## Budowanie własnego obrazu

```bash
# Zobacz opcje
./build.sh --help

# Zbuduj production
./build.sh --target production --version 1.0.0

# Zbuduj development
./build.sh --target development --version dev

# Lub z Makefile
make build        # production
make build-dev    # development
```

## Rozwiązywanie problemów

### Aplikacja nie odpowiada

```bash
# Sprawdź logi
docker-compose logs php-app

# Sprawdź status
docker-compose ps

# Restart
docker-compose restart
```

### Traefik routing nie działa (macOS/Linux)

```bash
# Dodaj do /etc/hosts
sudo bash -c 'cat >> /etc/hosts << EOF
127.0.0.1 app.localhost
127.0.0.1 dev.localhost
127.0.0.1 traefik.localhost
127.0.0.1 pma.localhost
127.0.0.1 redis.localhost
EOF'
```

### Port 80 zajęty

```bash
# Opcja 1: Zatrzymaj konfliktujący serwis
sudo lsof -i :80
sudo kill <PID>

# Opcja 2: Zmień port w docker-compose.yml
# Edytuj sekcję traefik ports:
#   - "8000:80"  # zamiast "80:80"
# Następnie: http://localhost:8000
```

### MySQL connection refused

```bash
# Poczekaj ~30 sekund na inicjalizację
docker-compose logs mysql

# Sprawdź health check
docker-compose ps mysql
# Powinno być: healthy
```

## Czyszczenie

```bash
# Zatrzymaj i usuń kontenery + wolumeny
docker-compose down -v

# Usuń niewykorzystane obrazy
docker system prune -f

# Lub z Makefile
make clean      # kontenery + wolumeny
make clean-all  # wszystko włącznie z obrazami
```

## Kubernetes (zaawansowane)

Wymaga: kubectl + Helm 3 + działający klaster K8s

```bash
# Lint chart
./helm/build-helm.sh --action lint

# Zobacz manifesty
./helm/build-helm.sh --action template

# Zainstaluj
./helm/build-helm.sh --action install

# Lub z Makefile
make helm-install
```

## Co dalej?

- Przeczytaj pełną dokumentację: [README.md](README.md)
- Zobacz opis zadania: [TASKS.md](TASKS.md)
- Wszystkie komendy: `make help`

---

**Potrzebujesz pomocy?** Sprawdź sekcję "Rozwiązywanie problemów" w README.md
