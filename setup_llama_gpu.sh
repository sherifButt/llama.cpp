#!/bin/bash

# Super minimal script to just download the model and create a start script

echo "Setting up minimal start script for Orpheus model..."

BASE_DIR=$(pwd)

# Create models directory and download the model if needed
mkdir -p models
if [ ! -f "models/Orpheus-3b-FT-Q8_0.gguf" ]; then
  echo "Downloading Orpheus model..."
  curl -L "https://huggingface.co/lex-au/Orpheus-3b-FT-Q8_0.gguf/resolve/main/Orpheus-3b-FT-Q8_0.gguf" -o "models/Orpheus-3b-FT-Q8_0.gguf"
else
  echo "Model already exists, skipping download."
fi

# Find the server binary
echo "Looking for server binary..."
SERVER_PATH=$(find $BASE_DIR/llama.cpp -name "server" -type f -executable 2>/dev/null)
if [ -z "$SERVER_PATH" ]; then
  SERVER_PATH=$(find $BASE_DIR/llama.cpp -name "*server*" -type f -executable 2>/dev/null | head -1)
  if [ -z "$SERVER_PATH" ]; then
    echo "ERROR: Cannot find server binary. Make sure llama.cpp is built correctly."
    exit 1
  fi
fi

SERVER_DIR=$(dirname "$SERVER_PATH")
SERVER_BIN=$(basename "$SERVER_PATH")
echo "Found server at: $SERVER_DIR/$SERVER_BIN"

# Create a simple start script with correct paths
cat > start-server.sh << EOL
#!/bin/bash
cd "$SERVER_DIR"
./$SERVER_BIN -m "$BASE_DIR/models/Orpheus-3b-FT-Q8_0.gguf" \\
  --host 0.0.0.0 \\
  --port 5006 \\
  --ctx-size 8192 \\
  --n-predict 8192 \\
  --rope-scaling linear \\
  --n-gpu-layers 99 \\
  --no-mmap
EOL

chmod +x start-server.sh

echo "======================================"
echo "Setup complete!"
echo "Run with: $BASE_DIR/start-server.sh"
echo "======================================"

# Option to start immediately
read -p "Start the server now? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
  ./start-server.sh
fi