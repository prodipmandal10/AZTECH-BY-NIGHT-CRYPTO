#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🔥 Starting Full AZTEC Node Setup by PRODIP with TMUX 🔥${NC}"

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update && sudo apt install -y nodejs

# Install required packages (including tmux)
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ufw apt-transport-https ca-certificates software-properties-common

# Setup Docker repo and install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Check versions
docker --version
docker-compose --version

# Install AZTEC CLI
bash -i <(curl -s https://install.aztec.network)

# Add AZTEC CLI to PATH if not already added
grep -qxF 'export PATH="$HOME/.aztec/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Update AZTEC CLI to latest
yes | aztec-up latest

# Setup firewall (UFW)
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080

# Enable UFW if not enabled
if sudo ufw status | grep -q inactive; then
    echo "y" | sudo ufw enable
fi

# Interactive inputs
echo -e "${GREEN}Please enter the following details:${NC}"

read -rp "SEPOLIA_RPC URL: " SEPOLIA_RPC
read -rp "BEACON_RPC URL: " BEACON_RPC
read -rp "Validator Private Key (with 0x): " PRIVATE_KEY
read -rp "EVM Address: " EVM_ADDRESS
read -rp "VPS IP Address: " VPS_IP

# Create restart script with inputs
cat > ~/restart-aztec.sh <<EOF
#!/bin/bash
while true; do
  echo "🟢 Starting Aztec node..."
  aztec start --node --archiver --sequencer \\
    --network alpha-testnet \\
    --l1-rpc-urls $SEPOLIA_RPC \\
    --l1-consensus-host-urls $BEACON_RPC \\
    --sequencer.validatorPrivateKey $PRIVATE_KEY \\
    --sequencer.coinbase $EVM_ADDRESS \\
    --p2p.p2pIp $VPS_IP \\
    --p2p.maxTxPoolSize 1000000000
  echo "🔴 Aztec node crashed. Restarting in 5 seconds..."
  sleep 5
done
EOF

chmod +x ~/restart-aztec.sh

# Run inside tmux session named AZ
tmux new-session -d -s AZ "bash ~/restart-aztec.sh"

echo -e "${GREEN}✅ Setup complete! AZTEC node is running inside tmux session named AZ.${NC}"
echo -e "${GREEN}👉 Attach to tmux using: tmux attach-session -t AZ${NC}"
