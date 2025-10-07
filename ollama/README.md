# Ollama Configuration

Stow-managed Ollama environment configuration for local AI models.

## Hardware
- **GPU**: NVIDIA RTX 2000 Ada (8GB VRAM)
- **RAM**: 64GB
- **Models**: DeepSeek Coder V2 16B, Llama 3.1 8B

## Configuration
Environment variables in `.config/environment.d/ollama.conf`:
- `OLLAMA_NUM_GPU=20` - GPU layers for optimal performance
- `OLLAMA_MAX_LOADED_MODELS=2` - Allow concurrent models
- `OLLAMA_FLASH_ATTENTION=true` - Performance optimization
- `OLLAMA_KEEP_ALIVE=5m` - Keep models loaded for 5 minutes

## Installation
```bash
cd ~/.dotfiles
stow ollama
```

## Models Installed
- `deepseek-coder-v2:16b` (8.9 GB) - Latest coding model, GPT-4 Turbo level
- `llama3.1:8b` (4.9 GB) - General tasks, multimodal support

## Usage
```bash
# List models
ollama list

# Run model
ollama run deepseek-coder-v2:16b
ollama run llama3.1:8b

# Service management
sudo systemctl status ollama
sudo systemctl restart ollama
```

## Integration
- Used by avante.nvim for local AI coding assistance
- Integrated with Neovim workflow for fast, private AI interactions
