#!/usr/bin/env bash

set -e

echo "=== Початок перевірки та встановлення інструментів DevOps ==="

UPDATED_APT=false
update_apt_once() {
    if [ "$UPDATED_APT" = false ]; then
        echo "[INFO] Оновлення списку пакетів apt..."
        sudo apt-get update -y
        UPDATED_APT=true
    fi
}

# 1. Перевірка та встановлення Docker
if command -v docker >/dev/null 2>&1; then
    echo "[OK] Docker вже встановлено: $(docker --version)"
else
    echo "[INSTALL] Встановлення Docker..."
    update_apt_once
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    DISTRO=$(. /etc/os-release && echo "$ID")
    curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker "$USER" || true
    echo "[SUCCESS] Docker успішно встановлено: $(docker --version)"
fi

# 2. Перевірка та встановлення Docker Compose
if docker compose version >/dev/null 2>&1; then
    echo "[OK] Docker Compose (plugin) вже встановлено: $(docker compose version)"
elif command -v docker-compose >/dev/null 2>&1; then
    echo "[OK] Docker Compose (standalone) вже встановлено: $(docker-compose --version)"
else
    echo "[INSTALL] Встановлення Docker Compose..."
    update_apt_once
    sudo apt-get install -y docker-compose-plugin
    echo "[SUCCESS] Docker Compose успішно встановлено: $(docker compose version)"
fi

# 3. Перевірка та встановлення Python (>= 3.9)
install_python=true
if command -v python3 >/dev/null 2>&1; then
    PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    if [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -ge 9 ]; then
        echo "[OK] Python >= 3.9 вже встановлено: $(python3 --version)"
        install_python=false
    else
        echo "[WARN] Знайдено застарілу версію Python: $(python3 --version). Потрібна >= 3.9."
    fi
fi

if [ "$install_python" = true ]; then
    echo "[INSTALL] Встановлення Python 3 та pip..."
    update_apt_once
    sudo apt-get install -y python3 python3-pip python3-venv
    echo "[SUCCESS] Python встановлено: $(python3 --version)"
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo "[INSTALL] Встановлення pip3..."
    update_apt_once
    sudo apt-get install -y python3-pip
fi

# 4. Перевірка та встановлення Django через pip
if python3 -m django --version >/dev/null 2>&1; then
    echo "[OK] Django вже встановлено: $(python3 -m django --version)"
else
    echo "[INSTALL] Встановлення Django через pip..."
    if pip3 install django 2>/dev/null; then
        echo "[SUCCESS] Django встановлено."
    else
        pip3 install --break-system-packages django
        echo "[SUCCESS] Django встановлено (з прапорцем --break-system-packages)."
    fi
    echo "[INFO] Версія Django: $(python3 -m django --version)"
fi

echo "=== Усі перевірки та встановлення завершено! ==="
