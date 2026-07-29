# Snipe-IT Install Scripts (Ubuntu 24.04 + Docker)

Automated installer for running Snipe-IT on Ubuntu 24.04 using Docker Compose.

## Quick start

    cd ~/snipe-it-install-scripts
    chmod +x install-snipeit-ubuntu24.sh
    ./install-snipeit-ubuntu24.sh --app-url http://<HOST_IP> --http-port 8080

Then open:

- http://<HOST_IP>:8080/setup

## What the installer handles

- Docker + Compose install
- Docker subnet conflict mitigation
- Writes `.env` with aligned `MYSQL_*` + `DB_*`
- `APP_URL` normalization with chosen port
- Starts `snipeit` + `mysql`
- Waits for MySQL readiness before Laravel config/cache actions
- Optional UFW open for app port

## Verify

    cd ~/snipeit
    docker compose ps
    curl -I http://127.0.0.1:8080
    curl -I http://<HOST_IP>:8080

Expected: `302` to `/setup` (or `200` after setup).

## Troubleshooting: DB access denied (1045)

    cd ~/snipeit
    docker compose down
    docker volume rm snipeit_mysql_data || true
    docker compose up -d
    docker compose exec -T snipeit php artisan config:clear || true
