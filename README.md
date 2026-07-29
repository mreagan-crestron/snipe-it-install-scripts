# Snipe-IT Install Scripts (Ubuntu 24.04)

This repo provides a one-shot installer for deploying the latest Snipe-IT on Ubuntu 24.04 using Docker.

## Files

- `install-snipeit-ubuntu24.sh` – automated installer
- `docker-compose.yml.template` – reference compose file
- `.env.example` – reference environment file

## Quick start

```bash
# 1) Download the installer
curl -fsSL https://raw.githubusercontent.com/mreagan-crestron/snipe-it-install-scripts/HEAD/install-snipeit-ubuntu24.sh -o install-snipeit-ubuntu24.sh

# 2) Make it executable
chmod +x install-snipeit-ubuntu24.sh

# 3) Run it
./install-snipeit-ubuntu24.sh --app-url http://YOUR_SERVER_IP --timezone UTC --http-port 8080
```

Then open `http://YOUR_SERVER_IP:8080` (or your chosen URL/port).

## Script options

```bash
./install-snipeit-ubuntu24.sh \
  --app-url http://YOUR_SERVER_IP_OR_DNS \
  [--project-dir ~/snipeit] \
  [--timezone UTC] \
  [--http-port 8080] \
  [--skip-ufw]
```

## Notes

- The script generates strong random DB passwords and app key automatically.
- Docker and Docker Compose plugin are installed from Docker's official apt repository.
- Data persists in Docker volumes: `snipeit_data` and `mysql_data`.

## Upgrade later

```bash
cd ~/snipeit
docker compose pull
docker compose up -d
```
