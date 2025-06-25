#!/bin/bash

echo "Step 1: Updating system and installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y

sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen ufw apt-transport-https ca-certificates software-properties-common

echo "Step 2: Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

echo "Step 3: Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

echo "Step 4: Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

docker --version && docker-compose --version

echo "Step 5: Installing Aztec CLI..."
bash -i <(curl -s https://install.aztec.network)

echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "Step 6: Updating Aztec CLI..."
aztec-up latest

echo "Step 7: Configuring firewall..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo ufw enable

echo "Step 8: Installing tmux if not installed..."
sudo apt install -y tmux

echo "Step 9: Creating tmux session named AZ and opening nano for script..."

tmux new-session -d -s AZ
tmux send-keys -t AZ "nano restart-aztec.sh" C-m

echo "Now inside tmux session 'AZ', nano will open for 'restart-aztec.sh' file."

echo "Please paste the following script inside nano and save it (Ctrl+O, Enter, Ctrl+X):"

cat <<'EOF'

#!/bin/bash
while true; do
  echo "🟢 Starting Aztec node..."
  aztec start --node --archiver --sequencer \
    --network alpha-testnet \
    --l1-rpc-urls SEPOLIA_RPC \
    --l1-consensus-host-urls BEACON_RPC \
    --sequencer.validatorPrivateKey PRIVATE_KEY_WITH_0X \
    --sequencer.coinbase EVM_ADDRESS \
    --p2p.p2pIp VPS_IP \
    --p2p.maxTxPoolSize 1000000000
  echo "🔴 Aztec node crashed. Restarting in 5 seconds..."
  sleep 5
done

EOF

echo ""
echo "After saving the file, run the following commands inside the tmux session:"
echo "chmod +x restart-aztec.sh"
echo "./restart-aztec.sh"
echo ""
echo "To attach to the tmux session later, use:"
echo "tmux attach -t AZ"
echo ""
echo "To detach from tmux session: Ctrl + B, then D"
