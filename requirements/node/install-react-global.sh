#!/bin/bash
set -e

echo "Installing global React testing dependencies (latest versions)..."

npm install --global \
    jest \
    jsdom \
    jest-environment-jsdom \
    @testing-library/react \
    @testing-library/jest-dom \
    react \
    react-dom \
    @babel/core \
    @babel/preset-env \
    @babel/preset-react \
    babel-jest

npm cache clean --force

# Dynamically get the global node_modules path
GLOBAL_NODE_PATH=$(npm root -g)
echo "Global node_modules path: $GLOBAL_NODE_PATH"

# Persist NODE_PATH for all users (login and non-login shells)
echo "export NODE_PATH=$GLOBAL_NODE_PATH" > /etc/profile.d/node-path.sh
echo "NODE_PATH=\"$GLOBAL_NODE_PATH\"" >> /etc/environment

# Also set for the current build session
export NODE_PATH="$GLOBAL_NODE_PATH"

echo "Global React testing packages installed."
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Jest version: $(jest --version)"
