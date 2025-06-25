#!/bin/bash
set -e

echo "=== AZTEC Node Full Setup Script ==="

# 1. Update and install dependencies (with -y for auto yes)
echo "[1/7] Updating system and installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen ufw apt-transport-https ca-certificates software-properties-common

# 2. Install Node.js 20
echo "[2/7] Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Install Docker
echo "[3/7] Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

# 4. Install Docker Compose
echo "[4/7] Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

docker --version && docker-compose --version

# 5. Install Aztec CLI
echo "[5/7] Installing Aztec CLI..."
bash -i <(curl -s https://install.aztec.network)
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
aztec-up latest

# 6. Configure firewall
echo "[6/7] Configuring firewall..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo ufw --force enable

# 7. Ask user input for node config
echo "[7/7] Please enter your AZTEC node configuration:"

read -p "Network (e.g. alpha-testnet): " NETWORK
read -p "L1 RPC URLs (e.g. https://sepolia.infura.io): " L1_RPC
read -p "L1 Consensus Host URLs (e.g. https://beacon.chain): " L1_CONSENSUS
read -p "Sequencer Validator Private Key (0x...): " PRIVATE_KEY
read -p "Sequencer Coinbase Address (0x...): " COINBASE
read -p "P2P IP Address: " P2P_IP

# Create restart script automatically with cat
echo "Creating restart-aztec.sh script..."

cat > ~/restart-aztec.sh << EOF
#!/bin/bash
while true; do
  echo "🟢 Starting Aztec node..."
  aztec start --node --archiver --sequencer \\
    --network $NETWORK \\
    --l1-rpc-urls $L1_RPC \\
    --l1-consensus-host-urls $L1_CONSENSUS \\
    --sequencer.validatorPrivateKey $PRIVATE_KEY \\
    --sequencer.coinbase $COINBASE \\
    --p2p.p2pIp $P2P_IP \\
    --p2p.maxTxPoolSize 1000000000
  echo "🔴 Aztec node crashed. Restarting in 5 seconds..."
  sleep 5
done
EOF

chmod +x ~/restart-aztec.sh

echo "Creating tmux session named 'AZTEC' and starting node..."

tmux new-session -d -s AZTEC "~/restart-aztec.sh"

echo "Setup complete!"
echo "To view logs, run: tmux attach -t AZTEC"
echo "To detach tmux session: Ctrl + B, then D"
