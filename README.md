# llama.cpp GPU Server Setup Script for RunPod

## How to Use This Script:

1. Create the script file on your RunPod instance:
```bash
# Create the script file (copy-paste the code above)
nano setup_llama_gpu.sh

# copy the script to root directory
sudo mv setup_llama_gpu.sh /root/
```

2. Make the script executable:
```bash
chmod +x setup_llama_gpu.sh
```

3. Run the script:
```bash
./setup_llama_gpu.sh
```

4. When prompted, choose whether to start the server immediately (y/n)

5. If you didn't start automatically, start the server with:
```bash
./start_llama_server.sh
```

6. **Important**: 
   - Go to your RunPod dashboard
   - Expose port 5006 to public internet
   - Note the URL (will be like https://xxxxx-xxxx.proxy.runpod.net)
   - Use this URL as the `ORPHEUS_API_URL` in your Orpheus-FastAPI configuration on your CPU server

This script focuses only on:
1. Installing dependencies for llama.cpp
2. Downloading the Orpheus model
3. Building llama.cpp with CUDA support
4. Creating a startup script for the server

The server will be accessible on port 5006 and will provide an OpenAI-compatible API endpoint that your Orpheus-FastAPI instance on your CPU server can connect to.