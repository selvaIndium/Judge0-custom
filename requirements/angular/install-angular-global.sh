#!/bin/bash
set -e

echo "Installing global Angular CLI and testing dependencies (latest versions)..."

npm install --global \
    @angular/cli \
    @angular/core \
    @angular/compiler \
    @angular/platform-browser \
    @angular/platform-browser-dynamic \
    @angular/common \
    @angular/router \
    @angular/forms \
    typescript \
    rxjs \
    zone.js \
    jasmine-core \
    karma \
    karma-chrome-launcher \
    karma-jasmine \
    karma-jasmine-html-reporter \
    @types/jasmine

npm cache clean --force

# Dynamically get the global node_modules path
GLOBAL_NODE_PATH=$(npm root -g)
echo "Global node_modules path: $GLOBAL_NODE_PATH"

# Persist NODE_PATH for all users (login and non-login shells)
echo "export NODE_PATH=$GLOBAL_NODE_PATH" > /etc/profile.d/node-path.sh
echo "NODE_PATH=\"$GLOBAL_NODE_PATH\"" >> /etc/environment

# Also set for the current build session
export NODE_PATH="$GLOBAL_NODE_PATH"

echo "Global Angular packages installed."
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Angular CLI version: $(ng version)"
