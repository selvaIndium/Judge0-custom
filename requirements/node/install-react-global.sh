#!/bin/bash
set -e

echo "Installing global React testing dependencies (latest versions)..."
npm install --global \
    jest \
    @testing-library/react \
    @testing-library/jest-dom \
    react \
    react-dom \
    @babel/core \
    @babel/preset-env \
    @babel/preset-react \
    babel-jest

npm cache clean --force

# Set NODE_PATH so Node can find global modules
echo 'export NODE_PATH=/usr/local/lib/node_modules' >> /etc/profile.d/node-path.sh
# Also set during build
export NODE_PATH=/usr/local/lib/node_modules

echo "Global React testing packages installed."
