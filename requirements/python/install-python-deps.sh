#!/bin/bash
set -e

echo "Installing python3-pip..."
apt-get update
apt-get install -y --no-install-recommends python3-pip
rm -rf /var/lib/apt/lists/*

echo "Upgrading pip, setuptools, wheel..."
pip3 install --upgrade pip setuptools wheel

echo "Installing Python packages..."
pip3 install --no-cache-dir \
    fastapi[all] \
    uvicorn \
    requests \
    pytest \
    httpx \

    #django==6.0.5 \
    #numpy==2.4.4 \
    #pandas==3.0.2 \
    #scikit-learn==1.8.0 \
    #matplotlib==3.10.9

echo "Python dependencies installed."
