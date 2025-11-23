#!/bin/sh
set -e

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Check if dist/tsl exists
if [ ! -f ./dist/tsl ]; then
  echo "Error: ./dist/tsl not found. Please run ./build.sh first."
  exit 1
fi

# Copy binary to ~/.local/bin
echo "Installing tsl to ~/.local/bin..."
cp ./dist/tsl ~/.local/bin/sl
chmod +x ~/.local/bin/sl

# Verify installation
if command -v tsl > /dev/null 2>&1; then
  echo "Installation successful! ✓"
  echo "Run 'tsl --help' to get started."
else
  echo "Installation complete, but ~/.local/bin is not in your PATH."
  echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
