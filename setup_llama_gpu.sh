#!/bin/bash

# Build llama.cpp and set up server with Orpheus model

echo "Building llama.cpp and setting up server for Orpheus model..."

BASE_DIR=$(pwd)

# Step 1: Build llama.cpp if not already built
if [ ! -d "build" ]; then
    echo "Building llama.cpp with GPU support..."
    mkdir -p build
    cd build
    cmake .. -DGGML_CUDA=ON -DLLAMA_CURL=OFF
    cmake --build . --config Release
    cd $BASE_DIR
else
    echo "Build directory exists, assuming llama.cpp is built."
fi

# Step 2: Download the model if needed
mkdir -p models
if [ ! -f "models/Orpheus-3b-FT-Q8_0.gguf" ]; then
    echo "Downloading Orpheus model..."
    curl -L "https://huggingface.co/lex-au/Orpheus-3b-FT-Q8_0.gguf/resolve/main/Orpheus-3b-FT-Q8_0.gguf" -o "models/Orpheus-3b-FT-Q8_0.gguf"
else
    echo "Model already exists, skipping download."
fi

# Step 3: Find the server binary
echo "Looking for server binary..."
SERVER_PATH=$(find $BASE_DIR/build -name "server" -type f -executable 2>/dev/null)
if [ -z "$SERVER_PATH" ]; then
    echo "Searching for any server-like binary..."
    SERVER_PATH=$(find $BASE_DIR/build -name "*server*" -type f -executable 2>/dev/null | head -1)
    if [ -z "$SERVER_PATH" ]; then
        echo "ERROR: Cannot find server binary."
        echo "Listing all executables in build directory:"
        find $BASE_DIR/build -type f -executable
        exit 1
    fi
fi

SERVER_DIR=$(dirname "$SERVER_PATH")
SERVER_BIN=$(basename "$SERVER_PATH")
echo "Found server at: $SERVER_DIR/$SERVER_BIN"

# Step 4: Create a start script
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
  --no-mmap \\
  --verbose
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