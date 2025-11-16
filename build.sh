#!/bin/sh
set -e

# Build the project
echo "Building binary..."
jpm build

# Create dist directory
mkdir -p dist

# Move binary to dist
echo "Moving binary to dist/ ..."
mv build/tsl dist/tsl

# Clean up
echo "Cleaning up..."
rm -rf build

echo "Build complete. Binary is in dist/tsl"
