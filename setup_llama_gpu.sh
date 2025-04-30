#!/bin/bash

# Clean start script for llama.cpp with GPU support

# Exit on error
set -e

echo "Setting up llama.cpp server with GPU support..."

# Install minimal requirements
apt-get update && apt-get install -y git cmake build-essential

# Define base directory
BASE_DIR=$(pwd)

# Remove any existing directory
if [ -d "llama_cpp" ]; then
  rm -rf llama_cpp
fi

# Clone a fresh copy of llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git llama_cpp
cd llama_cpp

# Build with GPU support
mkdir -p build
cd build
cmake .. -DGGML_CUDA=ON -DLLAMA_CURL=OFF
cmake --build . --config Release

# Look for the server executable
SERVER_PATH=$(find . -type f -executable -name "server" 2>/dev/null || find . -type f -executable -name "*server*" 2>/dev/null | head -1)

if [ -z "$SERVER_PATH" ]; then
  echo "Error: Could not find server executable. Listing available executables:"
  find . -type f -executable
  exit 1
fi

echo "Found server at: $SERVER_PATH"

# Go back to llama_cpp directory
cd "$BASE_DIR/llama_cpp"

# Create models directory
mkdir -p models

# Download the model if not already present
if [ ! -f "models/Orpheus-3b-FT-Q8_0.gguf" ]; then
  echo "Downloading Orpheus model..."
  curl -L "https://huggingface.co/lex-au/Orpheus-3b-FT-Q8_0.gguf/resolve/main/Orpheus-3b-FT-Q8_0.gguf" -o "models/Orpheus-3b-FT-Q8_0.gguf"
fi

# Create the startup script with correct paths
cat > start_server.sh << EOL
#!/bin/bash
cd "$BASE_DIR/llama_cpp/build"
$SERVER_PATH -m "$BASE_DIR/llama_cpp/models/Orpheus-3b-FT-Q8_0.gguf" \\
  --host 0.0.0.0 \\
  --port 5006 \\
  --ctx-size 8192 \\
  --n-predict 8192 \\
  --rope-scaling linear \\
  --n-gpu-layers 99 \\
  --verbose true \\
  --no-mmap
EOL

chmod +x start_server.sh

echo "======================================"
echo "Setup complete!"
echo "Run the server with: $BASE_DIR/llama_cpp/start_server.sh"
echo "======================================"

# Option to start immediately
read -p "Start the server now? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
  ./start_server.sh
fi