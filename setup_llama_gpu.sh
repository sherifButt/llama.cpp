#!/bin/bash

# Very simple llama.cpp GPU server setup

echo "Setting up minimal llama.cpp server for GPU..."

# Install minimal requirements
apt-get update && apt-get install -y git cmake build-essential

# Clone llama.cpp repository
rm -rf llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Build with GPU support (minimal options)
mkdir -p build && cd build
cmake .. -DLLAMA_CUBLAS=OFF -DGGML_CUDA=ON -DLLAMA_CURL=OFF
# No specific target, build all
cmake --build .

# Find the server binary
SERVER_PATH=$(find . -name "server" -type f -executable 2>/dev/null)
if [ -z "$SERVER_PATH" ]; then
  SERVER_PATH=$(find . -name "*server*" -type f -executable 2>/dev/null | head -1)
  if [ -z "$SERVER_PATH" ]; then
    echo "ERROR: Cannot find server binary. Build might have failed."
    echo "Checking for any executables:"
    find . -type f -executable
    exit 1
  fi
fi

SERVER_DIR=$(dirname "$SERVER_PATH")
SERVER_BIN=$(basename "$SERVER_PATH")
echo "Found server at: $SERVER_DIR/$SERVER_BIN"

cd ..

# Create models directory and download the model
mkdir -p models
if [ ! -f "models/Orpheus-3b-FT-Q8_0.gguf" ]; then
  curl -L "https://huggingface.co/lex-au/Orpheus-3b-FT-Q8_0.gguf/resolve/main/Orpheus-3b-FT-Q8_0.gguf" -o "models/Orpheus-3b-FT-Q8_0.gguf"
fi

# Create a simple start script with correct paths
cat > start-server.sh << EOL
#!/bin/bash
cd "$(pwd)/build/$SERVER_DIR"
./$SERVER_BIN -m "$(pwd)/models/Orpheus-3b-FT-Q8_0.gguf" \\
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
echo "Run with: $(pwd)/start-server.sh"
echo "======================================"

# Option to start immediately
read -p "Start the server now? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
  ./start-server.sh
fi