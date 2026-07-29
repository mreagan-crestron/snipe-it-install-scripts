#!/usr/bin/env bash
set -euo pipefail

# Snipe-IT installer for Ubuntu 24.04 (Noble)
# - Installs Docker Engine + Compose plugin
# - Creates Snipe-IT project files
# - Starts Snipe-IT + MySQL via docker compose
#
# Usage:
#   chmod +x install-snipeit-ubuntu24.sh
#   ./install-snipeit-ubuntu24.sh --app-url http://SERVER_IP_OR_DNS [--project-dir ~/snipeit]
#
# Optional flags:
#   --app-url <url>        Required. Public URL or IP for Snipe-IT (http://x.x.x.x or https://host)
#   --project-dir <path>   Default: ~/snipeit
#   --timezone <tz>        Default: UTC (ex: America/Chicago)
#   --http-port <port>     Default: 8080
#   --skip-ufw             Do not open firewall port

APP_URL=""
PROJECT_DIR="${HOME}/snipeit"
APP_TIMEZONE="UTC"
HTTP_PORT="8080"
SKIP_UFW="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-url)
      APP_URL="${2:-}"
      shift 2
      ;;
    --project-dir)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --timezone)
      APP_TIMEZONE="${2:-}"
      shift 2
      ;;
    --http-port)
      HTTP_PORT="${2:-}"
      shift 2
      ;;
    --skip-ufw)
      SKIP_UFW="true"
      shift
      ;;
    -h|--help)
      sed -n '1,40p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$APP_URL" ]]; then
  echo "ERROR: --app-url is required"
  echo "Example: ./install-snipeit-ubuntu24.sh --app-url http://10.0.0.10"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "==> Installing prerequisites"
$SUDO apt update
$SUDO apt install -y ca-certificates curl gnupg lsb-release openssl

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  echo "==> Adding Docker GPG key"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
fi

if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
  echo "==> Adding Docker apt repository"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
fi

echo "==> Installing Docker Engine + Compose"
$SUDO apt update
$SUDO apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
$SUDO systemctl enable --now docker

# Generate strong passwords and APP_KEY
MYSQL_ROOT_PASSWORD="$(openssl rand -base64 32 | tr -d '\n')"
MYSQL_PASSWORD="$(openssl rand -base64 32 | tr -d '\n')"
APP_KEY_RAW="$(openssl rand -base64 32 | tr -d '\n')"
APP_KEY="base64:${APP_KEY_RAW}"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "==> Writing .env"
cat > .env <<EOF
APP_URL=${APP_URL}
APP_KEY=${APP_KEY}
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=${APP_TIMEZONE}

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=snipeit
MYSQL_USER=snipeit
MYSQL_PASSWORD=${MYSQL_PASSWORD}

PUID=1000
PGID=1000
EOF

MYSQL_DATABASE=snipeit
MYSQL_USER=snipeit
MYSQL_PASSWORD=${MYSQL_PASSWORD}
echo "==> Writing docker-compose.yml"
cat > docker-compose.yml <<EOF
services:
  snipeit:
    image: snipe/snipe-it:latest
    container_name: snipeit
    restart: unless-stopped
    ports:
      - "${HTTP_PORT}:80"
    env_file:
      - .env
    depends_on:
      - mysql
    volumes:
      - snipeit_data:/var/lib/snipeit

  mysql:
    image: mysql:8.0
    container_name: snipeit-mysql
    restart: unless-stopped
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  snipeit_data:
  mysql_data:
EOF

echo "==> Starting containers"
$SUDO docker compose up -d

if [[ "$SKIP_UFW" != "true" ]]; then
  if command -v ufw >/dev/null 2>&1; then
    echo "==> Opening firewall port ${HTTP_PORT}/tcp via UFW"
    $SUDO ufw allow "${HTTP_PORT}/tcp" || true
  fi
fi

echo
echo "Install complete."
echo "Project directory: $PROJECT_DIR"
echo "Snipe-IT URL: ${APP_URL}"
echo "If using IP access, browse to: ${APP_URL} (port ${HTTP_PORT} mapped to container port 80)"
echo
echo "Useful commands:"
echo "  cd ${PROJECT_DIR}"
echo "  docker compose ps"
echo "  docker compose logs -f snipeit"
