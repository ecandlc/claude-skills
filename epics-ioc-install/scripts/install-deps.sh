#!/usr/bin/env bash
# install-deps.sh — Install system dependencies for EPICS IOC with areaDetector + Mythen2
# Usage: bash install-deps.sh
# Requires: sudo access, apt-based Linux (Debian/Ubuntu/WSL2)

set -euo pipefail

echo "==> Updating package lists..."
sudo apt-get update

echo "==> Installing build tools..."
sudo apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    git \
    wget \
    perl \
    re2c

echo "==> Installing EPICS Base dependencies..."
sudo apt-get install -y \
    libreadline-dev \
    libncurses-dev

echo "==> Installing areaDetector external library dependencies..."
sudo apt-get install -y \
    libhdf5-dev \
    libhdf5-serial-dev \
    libtiff-dev \
    libjpeg-dev \
    libxml2-dev \
    libssl-dev \
    zlib1g-dev

echo "==> Verifying key tools..."
for cmd in gcc make perl git; do
    if command -v "$cmd" &>/dev/null; then
        echo "  [OK] $cmd: $(command -v $cmd)"
    else
        echo "  [FAIL] $cmd not found — check the installation above"
        exit 1
    fi
done

echo ""
echo "==> All dependencies installed successfully."
echo "    Proceed to building EPICS Base."
