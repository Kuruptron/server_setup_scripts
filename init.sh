#!/bin/bash
# initial-setup.sh
# Script to update Ubuntu, install Docker, Git, GitHub CLI, and CasaOS

set -e

echo ">>> Updating and upgrading system..."
sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt clean

echo ">>> Installing basic utilities..."
sudo apt install -y \
    curl \
    wget \
    nano \
    git \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    snapd

echo ">>> Installing GitHub CLI (gh)..."
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -y
sudo apt install gh -y

echo ">>> Setting up Docker repository..."
# Remove old versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Add Docker’s official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>> Installing Docker..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Adding current user to docker group..."
sudo usermod -aG docker $USER

echo ">>> Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo ">>> Installing CasaOS..."
curl -fsSL https://get.casaos.io | sudo bash

echo ">>> All installations complete!"
echo "NOTE: Log out and back in (or run: newgrp docker) to use Docker without sudo."

echo ">>> Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled

echo ">>> Bringing up Tailscale and advertising exit node..."
sudo tailscale up --accept-dns=true --advertise-exit-node




echo ">>> Setting up Navidrome in /opt/navidrome..."
sudo mkdir -p /opt/navidrome
cd /opt/navidrome

# Create docker-compose.yml for Navidrome
cat <<EOF | sudo tee /opt/navidrome/docker-compose.yml
version: "3.8"
services:
  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    user: "\${UID}:\${GID}"
    ports:
      - "4533:4533"
    volumes:
      - ./data:/data
      - ./music:/music
    restart: unless-stopped
EOF

# Start Navidrome
sudo docker compose up -d
