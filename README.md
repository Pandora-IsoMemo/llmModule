# llmModule

<!-- badges: start -->
[![R-CMD-check](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/pkgdown.yaml)
[![docker-publish](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/docker-publish.yml)
<!-- badges: end -->

`llmModule` provides a structured R interface for working with remote and local
Large Language Model (LLM) APIs through a consistent S3-based workflow.

It is designed for script and package usage (without requiring you to run Shiny), with
support for:

- Remote providers through `RemoteLlmApi` and bridge-based providers
- Local Ollama models through `LocalLlmApi`
- Prompt configuration via `LlmPromptConfig`
- Structured response handling via `LlmResponse`

> Note: `llmModule` still exports Shiny-facing helpers for compatibility
> (e.g. `startApplication()`), but for actively maintained Shiny workflows
> prefer the separate package `llmModuleS`.

## 🚀 Features

- Modular, object-oriented interface using S3 classes:
  - `RemoteLlmApi` for legacy remote providers (OpenAI, DeepSeek)
  - Bridge routing via `new_BridgedLlmApi()` for additional providers, returning
    `EllmerLlmApi` (or `RemoteLlmApi` for legacy providers)
    (e.g., Anthropic, Gemini, Groq, Mistral, OpenRouter)
  - `LocalLlmApi` for local Ollama servers
  - `LlmPromptConfig` to configure prompt messages and parameters
  - `LlmResponse` for structured handling of responses
- Validation model aligned with runtime API behavior:
  - Constructor-time checks validate credentials (preferred: `api_key` string;
    deprecated fallback: `api_key_path` file path)
  - Internet and credential validity checks occur at runtime when calling
    `get_llm_models()` or `send_prompt()`
- Local model support (via [Ollama](https://ollama.com)):
  - Allows to pull new models
  - Allows exclusion of deprecated or irrelevant models via `exclude_pattern`
- Unified method interface:
  - `get_llm_models()` to fetch available models
  - `send_prompt()` to submit prompts and retrieve responses
- Optional Docker integration for local deployment (see below)

## 🧪 Quick Examples

### Cloud Provider Example

```r
library(llmModule)

# Create an API object
api <- new_BridgedLlmApi(
  provider = "Anthropic",
  api_key = Sys.getenv("ANTHROPIC_API_KEY")
)

# Set up a prompt
prompt <- new_LlmPromptConfig(
  model = "gpt-4.1",
  prompt_content = "What's the capital of Italy?"
)

# Send the prompt
result <- send_prompt(api, prompt)

# Handle runtime validation/network errors
if (!is.null(attr(result, "error"))) {
  message(attr(result, "error"))
} else {
  result$choices[[1]]$message$content
}
```

### Local Ollama Example

```r
library(llmModule)

# Initialize and refresh the local Ollama model manager
manager <- new_OllamaModelManager()
manager <- update(manager)

# Create a local API object and select or pull the model if needed
api <- new_LocalLlmApi(manager, "tinyllama")
prompt <- new_LlmPromptConfig(
  prompt_content = "Summarize entropy in one sentence.",
  model = "tinyllama:latest"
)

# Send prompt and read the generated text
response <- new_LlmResponse(api, prompt)
response$generated_text
```

### One-call Wrapper Example

```r
library(llmModule)

# Call a cloud provider in one step
result <- ask_llm(
  provider = "OpenAI",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  model = "gpt-4.1",
  prompt_content = "What's the capital of Italy?",
  temperature = 0.2,
  max_tokens = 50
)

# Handle runtime validation and network errors
if (!is.null(attr(result, "error"))) {
  message(attr(result, "error"))
} else {
  result$choices[[1]]$message$content
}
```

### Prompt arguments (quick orientation)

`ask_llm()` forwards additional arguments to `new_LlmPromptConfig()`.
Commonly used arguments are:

- `temperature`
- `max_tokens`
- `top_p`
- `n`
- `stop`
- `seed`
- `presence_penalty`
- `frequency_penalty`
- `logprobs`

For a full walkthrough (including provider/model discovery and argument details),
see the vignette:
<https://pandora-isomemo.github.io/llmModule/articles/prompt-configuration-and-wrapper.html>

### Discover Providers and Models First

```r
library(llmModule)

# 1) List available providers (includes Ollama only if reachable)
providers <- get_providers(ollama_available = is_ollama_running())
providers

# 2) Create the API object for your selected provider
api <- new_BridgedLlmApi(
  provider = "OpenAI",
  api_key = Sys.getenv("OPENAI_API_KEY")
)

# 3) List models for this provider
models <- get_llm_models(api)
models

# 4) Use one model in the one-call wrapper
result <- ask_llm(
  provider = "OpenAI",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  model = "gpt-4.1",
  prompt_content = "Summarize entropy in one sentence."
)

if (!is.null(attr(result, "error"))) {
  message(attr(result, "error"))
} else {
  result$choices[[1]]$message$content
}
```

## 📦 Docker Setup (optional)

This Docker setup is mainly for legacy app workflows. For Shiny-based UI usage,
please use `llmModuleS`.

### ✅ 1. Install the software Docker

Download installation files from one of the links below and follow installation
instructions:

* [Windows](https://docs.docker.com/desktop/windows/install/)
* [MacOS](https://docs.docker.com/desktop/install/mac-install/)
* [Linux](https://docs.docker.com/desktop/install/linux-install/)

After Docker is installed you can pull & run the app manually.

### 🚀 2. Run the Docker stack with Compose

**Open a terminal (command line):**

- Windows command line: 
   1. Open the Start menu or press the `Windows key` + `R`; 
   2. Type cmd or cmd.exe in the Run command box;
   3. Press Enter.
- MacOS: open the Terminal app.
- Linux: most Linux systems use the same default keyboard shortcut to start the
  command line: `Ctrl`-`Alt`-`T` or `Super`-`T`

To start the stack you need the
[docker-compose.yaml](https://github.com/Pandora-IsoMemo/llmModule/blob/main/docker-compose.yml) of
this Repository. You can either:

**Run directly without cloning the repo:**

```
curl -sL https://raw.githubusercontent.com/Pandora-IsoMemo/llmModule/refs/heads/main/docker-compose.yml | docker compose -f - up
```

**OR: Clone the repository and run in the project directory:**

```
git clone https://github.com/Pandora-IsoMemo/llmModule.git
cd llmModule
docker compose up
```

These commands will:

1. The first time you run this, it will download the necessary Docker images for 
    - `ollama` (for model serving and its REST API) and 
    - the `llm-module` container image used in this repository's Docker workflow.
2. After images are pulled, a Docker network and a Docker volume will be created, and both container will start.
3. For an actively maintained Shiny frontend, use `llmModuleS`.


### 🚀 3. Run the stack with a custom Ollama models path (optional)

To use your own pre-downloaded Ollama models, specify a custom path by setting the 
`OLLAMA_LOCAL_MODELS_PATH` environment variable.

This requires cloning the repository and running Docker Compose from the project directory.

```bash
OLLAMA_LOCAL_MODELS_PATH=/path/to/your/models docker compose up
```

Default locations for Ollama models:

- linux: `/usr/share/ollama/.ollama`
- macOS: `~/.ollama`
- windows: `C:\\Users\\<username>\\.ollama`

This will mount your local models into the container for faster startup and persistent access.

## Notes for developers

### Documentation

When adding information to the _help_ sites, _docstrings_ or the _vignette_ of this 
package, please update documentation locally as follows. The documentation of
the main branch is build automatically via github action.

```R
devtools::document() # or CTRL + SHIFT + D in RStudio
devtools::build_site()
```

### Local testing

To build and run the app locally:

```bash
docker compose up --build
```

Use `--build` if:

- You made changes to source code or Dockerfiles,
- Or you're testing a fresh environment.

To run with a custom models path:

```bash
OLLAMA_LOCAL_MODELS_PATH=</path/to/your/models> docker compose up --build
```

*Tip:* Use `docker compose down` to stop and clean up the containers when done.
