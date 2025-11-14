#!/bin/bash
set -euo pipefail

echo "1) Ensure old snap docker is gone (no-op if already removed)"
sudo snap remove docker 2>/dev/null || true
sudo rm -f /usr/bin/docker 2>/dev/null || true

echo "2) Install prerequisites"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

echo "3) Add Docker GPG key and apt repo"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "4) Update apt and install Docker CE + containerd"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "5) Configure containerd to use systemd cgroups"
sudo mkdir -p /etc/containerd
if [ -f /etc/containerd/config.toml ]; then
  sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak.$(date +%Y%m%d-%H%M%S)
fi
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
# enable systemd cgroups (idempotent)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

echo "6) Create/overwrite daemon.json with safe defaults (backing up if exists)"
if [ -f /etc/docker/daemon.json ]; then
  sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d-%H%M%S)
fi
cat <<'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

echo "7) Restart services and enable docker"
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl restart docker
sudo systemctl enable docker --now

echo "8) Verify installation"
echo " which docker -> $(command -v docker || true)"
docker --version || true
containerd --version || true
sudo docker info --format 'Server: {{.ServerVersion}} | CgroupDriver: {{.CgroupDriver}} | CgroupVersion: {{.CgroupVersion}} | Storage: {{.Driver}}' || true

echo "9) Quick functional test"
set +e
sudo docker run -d --name testnginx -p 8080:80 nginx:latest
sleep 4
sudo docker ps --filter name=testnginx
echo "Stopping test container..."
sudo docker stop testnginx
sudo docker rm testnginx
set -e

echo "Done. If any command failed above, copy the failing output and paste it here."

