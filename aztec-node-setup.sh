#!/bin/bash

set -e  # Exit on any error

# 1. Blinking Banner
clear
echo -e "\e[5;32m"
echo " █████╗ ████████╗████████╗ ██████╗ ███████╗"
echo "██╔══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗██╔════╝"
echo "███████║   ██║      ██║   ██║   ██║█████╗  "
echo "██╔══██║   ██║      ██║   ██║   ██║██╔══╝  "
echo "██║  ██║   ██║      ██║   ╚██████╔╝███████╗"
echo "╚═╝  ╚═╝   ╚═╝      ╚═╝    ╚═════╝ ╚══════╝"
echo "              P R O D I P"
echo -e "\e[0m"
sleep 2

# 2. Update & install dependencies
echo "🛠️  Updating system and installing dependencies..."
yes | sudo apt-get update
yes | sudo apt-get upgrade -y

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
yes | sudo apt-get install -y nodejs

# Essential packages
yes | sudo apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf screen htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ufw apt-transport-https ca-certificates software-properties-common

# Docker install
echo "🐳 Installing Docker and Docker Compose..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
yes | sudo apt-get update
yes | sudo apt-get install -y docker-ce
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

# Docker Compose install
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker versions
docker --version
docker-compose --version

# AZTEC CLI install
echo "🔽 Installing AZTEC CLI..."
bash -i <(curl -s https://install.aztec.network)

# Add AZTEC CLI to PATH
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Pull latest AZTEC docker image
echo "⬇️ Pulling latest AZTEC docker image..."
aztec-up latest

# Setup UFW firewall
echo "🛡️ Configuring firewall..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo ufw --force enable

# 3. Prompt user for configuration
echo ""
echo "📝 Please enter AZTEC node configuration:"
read -p "Network (e.g. alpha-testnet): " NETWORK
NETWORK=${NETWORK:-alpha-testnet}  # Default

read -p "L1 RPC URLs (e.g. http://...): " L1_RPC
read -p "L1 Consensus Host URLs (e.g. http://...): " L1_CONSENSUS
read -p "Sequencer Validator Private Key (0x...): " PRIVATE_KEY
read -p "Sequencer Coinbase Address (0x...): " COINBASE
read -p "P2P IP Address: " P2P_IP

# 4. Construct AZTEC start command
AZTEC_CMD="aztec start --node --archiver --sequencer \
--network $NETWORK \
--l1-rpc-urls $L1_RPC \
--l1-consensus-host-urls $L1_CONSENSUS \
--sequencer.validatorPrivateKey $PRIVATE_KEY \
--sequencer.coinbase $COINBASE \
--p2p.p2pIp $P2P_IP"

# 5. Start in screen session named AZTEC-PRODIP with auto-restart loop
SESSION="AZTEC-PRODIP"

echo ""
echo "🚀 Starting AZTEC node in screen session '$SESSION'..."

# Kill old session if exists
if screen -list | grep -q "$SESSION"; then
  echo "🛑 Killing old screen session $SESSION..."
  screen -S "$SESSION" -X quit
fi

# Start screen session with auto-restart script inside
screen -dmS "$SESSION" bash -c "
while true; do
  echo '🟢 Starting AZTEC node...'
  $AZTEC_CMD
  echo '🔴 AZTEC node crashed or stopped. Restarting in 5 seconds...'
  sleep 5
done
"

echo ""
echo "✅ AZTEC node started inside screen session '$SESSION'."
echo "👉 To view logs: screen -r $SESSION"
echo "👉 To detach session: Press Ctrl+A then D"
