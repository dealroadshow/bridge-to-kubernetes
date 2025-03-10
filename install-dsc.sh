#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Install dotnet via brew if not installed
if ! command -v dotnet &> /dev/null; then
    brew install dotnet@8
fi

# Clone the repository
REPO_URL="git@github.com:dealroadshow/bridge-to-kubernetes.git"
REPO_DIR="bridge-to-kubernetes"

git clone "$REPO_URL" "$REPO_DIR" || true
cd "$REPO_DIR"

# Restore dependencies
dotnet restore src/all.sln

# Publish endpointmanager
dotnet publish src/endpointmanager -c Release

# Publish dsc and capture output
PUBLISH_DIR=$(dotnet publish src/dsc --self-contained=true -c Release /p:PublishSingleFile=true -r osx-arm64 | tail -1 | grep "dsc ->" | awk '{print $3}')
printf "%s\n\n" "$PUBLISH_DIR"

if [ -z "$PUBLISH_DIR" ]; then
    echo "Failed to determine publish directory."
    exit 1
fi

# Change to the publish directory
cd "$PUBLISH_DIR"

# Make the dsc file executable
chmod +x ./dsc

# Copy dsc to /usr/local/bin
sudo cp ./dsc /usr/local/bin/

echo "Installation completed successfully."
