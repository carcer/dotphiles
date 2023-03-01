#!/bin/bash

set -e

echo "Docker post setup"

sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "Enabling bluetooth"

sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service