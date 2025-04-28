# llmModule

<!-- badges: start -->
[![R-CMD-check](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Notes for developers

Run test app with docker-compose with ollama option:

```bash
docker compose up --build
```

Run test app with docker-compose with ollama option and point to the folder of your ollama models, e.g. default folders can be on

- linux: `/usr/share/ollama/.ollama`
- macOS: `~/.ollama`
- windows: `C:\\Users\\<username>\\.ollama`

```bash
OLLAMA_LOCAL_MODELS_PATH=</path/to/your/models> docker compose up --build
```
