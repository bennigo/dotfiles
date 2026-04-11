# Ollama Configuration

Stow-managed Ollama environment configuration for local AI models.

## Hardware Constraints

- **GPU**: NVIDIA RTX 2000 Ada (8GB VRAM)
- **RAM**: 64GB
- **VRAM sweet spot**: Models up to ~7B (Q4) fit fully in GPU — fast inference
- `deepseek-coder-v2:16b` (8.9 GB) spills to RAM — usable but noticeably slower
- `OLLAMA_MAX_LOADED_MODELS=2` allows embedding model + one main model simultaneously
- `OLLAMA_KEEP_ALIVE=5m` — models stay loaded 5 min after last request
- Avoid frequent swaps between 16B and 7B models

## Configuration

Environment variables in `.config/environment.d/ollama.conf`:
- `OLLAMA_NUM_GPU=20` — GPU layers for optimal performance
- `OLLAMA_MAX_LOADED_MODELS=2` — Allow concurrent models (e.g., embedding + chat)
- `OLLAMA_FLASH_ATTENTION=true` — Performance optimization
- `OLLAMA_KEEP_ALIVE=5m` — Keep models loaded for 5 minutes
- `OLLAMA_HOST=127.0.0.1:11434` — Local-only access

## Installation

```bash
cd ~/.dotfiles
stow ollama
```

## Model Inventory

| Model | Size | Category | Use |
|-------|------|----------|-----|
| `qwen3.5` | 6.6 GB | General (default) | Chat, analysis, translation |
| `qwen3:8b` | 5.2 GB | General | Multilingual, function calling |
| `qwen2.5:7b` | 4.7 GB | General | All-rounder |
| `llama3.1:8b` | 4.9 GB | General | Meta's workhorse |
| `llama3.2:3b` | 2.0 GB | Fast | Quick Q&A, drafts |
| `phi3.5` | 2.2 GB | Lightweight | Resource-constrained tasks |
| `deepseek-r1:8b` | 5.2 GB | Reasoning | Math, logic, step-by-step |
| `qwen2.5-coder:7b` | 4.7 GB | Coding | Code gen, review, refactor |
| `deepseek-coder:6.7b` | 4.1 GB | Coding | Legacy, superseded by qwen2.5-coder |
| `deepseek-coder-v2:16b` | 8.9 GB | Coding (heavy) | Complex multi-file (partial GPU offload) |
| `moondream` | 1.7 GB | Vision | Image understanding |
| `mxbai-embed-large` | 669 MB | Embeddings | RAG/search pipelines |

## Model Routing

Context-based model selection rules — encoded in shell aliases and Crush provider config.

| Context | Model | Why |
|---------|-------|-----|
| **Quick Q&A / drafts** | `llama3.2:3b` | Fast first-token, fits easily in VRAM |
| **General chat / analysis** | `qwen3.5` | Best quality at VRAM limit, 128K context |
| **Reasoning / math / logic** | `deepseek-r1:8b` | Chain-of-thought with thinking tokens |
| **Translation (any language)** | `qwen3.5` | Strongest multilingual coverage (incl. Farsi) |
| **Coding (general)** | `qwen2.5-coder:7b` | Purpose-built for code, fits in VRAM |
| **Coding (complex / multi-file)** | `deepseek-coder-v2:16b` | Higher quality, partial GPU offload (slower) |
| **Image understanding** | `moondream` | Lightweight vision model (1.7 GB) |
| **Embeddings / RAG** | `mxbai-embed-large` | Runs alongside any other model |
| **Lightweight / resource-constrained** | `phi3.5` | 3.8B params, good quality-to-size ratio |

### Gaps (no local model needed)

- **Structured JSON output** — `qwen3.5` supports it natively
- **Long document processing** — `qwen3.5` has 128K context, sufficient for most
- **Speech-to-text** — handled by `faster-whisper` (not Ollama)
- **Dedicated Farsi translation** — `qwen3.5` handles it well; for critical work, use cloud APIs

## Shell Aliases

Defined in `zsh/.config/zsh/aliases.zsh`:

```bash
ai            # Default: qwen3.5 (general)
ai-fast       # Quick: llama3.2:3b
ai-code       # Coding: qwen2.5-coder:7b
ai-reason     # Reasoning: deepseek-r1:8b
ai-translate  # Translation: qwen3.5 with translation system prompt
ai-vision     # Vision: moondream
ai-heavy      # Heavy coding: deepseek-coder-v2:16b
```

## Usage

```bash
# Direct usage
ollama run qwen3.5
ollama run qwen2.5-coder:7b

# Service management
sudo systemctl status ollama
sudo systemctl restart ollama
```

## Integration

- **Crush TUI**: Configured as `ollama` provider in `crush.json` (OpenAI-compatible API at localhost:11434/v1/)
- **avante.nvim**: Local AI coding assistance in Neovim
- **Shell aliases**: Context-based model selection via `ai-*` commands
