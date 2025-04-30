#!/bin/bash

# llama.cpp GPU Server Setup for RunPod
# This script sets up only the GPU inference component (no Orpheus-FastAPI)

echo "============================================"
echo "    llama.cpp GPU Server Setup for Orpheus  "
echo "============================================"

# Exit on error
set -e

# Function to check if a command succeeded
check_status() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1 failed!"
    exit 1
  fi
}

# Determine current directory to use as base
BASE_DIR=$(pwd)
echo "Using base directory: $BASE_DIR"

# Install required packages
echo "[1/4] Installing required packages..."
apt-get update && apt-get install -y git cmake build-essential curl
check_status "Package installation"

# Create model directory
echo "[2/4] Creating model directory..."
mkdir -p "$BASE_DIR/models"
check_status "Model directory creation"

# Download the Orpheus model
echo "[3/4] Downloading the Orpheus model (this may take a few minutes)..."
MODEL_FILE="$BASE_DIR/models/Orpheus-3b-FT-Q8_0.gguf"
if [ -f "$MODEL_FILE" ]; then
  echo "Model file already exists. Skipping download."
else
  curl -L "https://huggingface.co/lex-au/Orpheus-3b-FT-Q8_0.gguf/resolve/main/Orpheus-3b-FT-Q8_0.gguf" -o "$MODEL_FILE"
  check_status "Model download"
fi

# Install llama.cpp with GPU support
echo "[4/4] Installing llama.cpp server with CMake..."
cd "$BASE_DIR"
if [ -d "llama.cpp" ]; then
  echo "Removing existing llama.cpp directory..."
  rm -rf llama.cpp
fi

git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
mkdir -p build
cd build
cmake .. -DLLAMA_CUBLAS=ON
cmake --build . --config Release
check_status "llama.cpp compilation with CMake"

# Check if server binary exists
if [ ! -f "$BASE_DIR/llama.cpp/build/bin/llama-server" ]; then
  echo "ERROR: llama-server binary not found in expected path!"
  echo "Looking for server binary in build directory..."
  LLAMA_SERVER_PATH=$(find "$BASE_DIR/llama.cpp/build" -name "llama-server" -type f | head -1)
  if [ -z "$LLAMA_SERVER_PATH" ]; then
    echo "ERROR: Could not find llama-server binary anywhere!"
    exit 1
  else
    echo "Found server at: $LLAMA_SERVER_PATH"
    # Create bin directory and copy server
    mkdir -p "$BASE_DIR/llama.cpp/build/bin"
    cp "$LLAMA_SERVER_PATH" "$BASE_DIR/llama.cpp/build/bin/"
  fi
fi

# Create a start script for llama.cpp server
echo "Creating start script..."
cat > "$BASE_DIR/start_llama_server.sh" << EOL
#!/bin/bash
cd "$BASE_DIR/llama.cpp/build/bin"
./llama-server -m "$BASE_DIR/models/Orpheus-3b-FT-Q8_0.gguf" \\
  --host 0.0.0.0 \\
  --port 5006 \\
  --ctx-size 8192 \\
  --n-predict 8192 \\
  --threads 4 \\
  --threads-batch 4 \\
  --rope-scaling linear \\
  --n-gpu-layers 99 \\
  --no-mmap \\
  --no-slots \\
  --no-webui
EOL

chmod +x "$BASE_DIR/start_llama_server.sh"

echo "============================================"
echo "        Setup completed successfully!       "
echo "============================================"
echo ""
echo "To start the llama.cpp GPU server, run:"
echo "$BASE_DIR/start_llama_server.sh"
echo ""
echo "This will start the llama.cpp server on port 5006"
echo "Remember to expose port 5006 in your RunPod dashboard"
echo "Use the generated URL as the ORPHEUS_API_URL in your"
echo "Orpheus-FastAPI configuration on your CPU server."
echo "============================================"

# Option to start the server
read -p "Would you like to start the server now? (y/n): " start_server
if [[ $start_server == "y" || $start_server == "Y" ]]; then
    echo "Starting llama.cpp server..."
    "$BASE_DIR/start_llama_server.sh"
else
    echo "You can start the server later with '$BASE_DIR/start_llama_server.sh'"
fi