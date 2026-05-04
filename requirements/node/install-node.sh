#!/bin/bash
set -e

echo "Installing Node.js 24.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

echo "Upgrading npm to latest..."
npm install -g npm@latest

echo "Node version: $(node -v)"
echo "npm version: $(npm -v)"
