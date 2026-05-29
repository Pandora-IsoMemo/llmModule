# llmModule (development version)

<!-- badges: start -->
[![R-CMD-check](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/pkgdown.yaml)
[![docker-publish](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/docker-publish.yml)
<!-- badges: end -->

`llmModule` provides a structured R interface for working with remote and local
Large Language Model (LLM) APIs through a consistent S3-based workflow.

It is designed for script and package usage (without requiring Shiny), with
support for:

- Remote providers through `RemoteLlmApi` and bridge-based providers
- Local Ollama models through `LocalLlmApi`
- Prompt configuration via `LlmPromptConfig`
- Structured response handling via `LlmResponse`

> Note: Shiny modules were extracted into the separate package `llmModuleS` and
> are deprecated in `llmModule`.

## 🚀 Features

- Modular, object-oriented interface using S3 classes:
  - `RemoteLlmApi` for legacy remote providers (OpenAI, DeepSeek)
  - `BridgedLlmApi` routing via `new_BridgedLlmApi()` for additional providers
    (e.g., Anthropic, Gemini, Groq, Mistral, OpenRouter)
  - `LocalLlmApi` for local Ollama servers
  - `LlmPromptConfig` to configure prompt messages and parameters
  - `LlmResponse` for structured handling of responses
- Validation model aligned with runtime API behavior:
  - Constructor-time checks validate local key file structure (path, one-line format, minimum length)
  - Internet and credential validity checks occur at runtime when calling
    `get_llm_models()` or `send_prompt()`
- Local model support (via [Ollama](https://ollama.com)):
  - Allows to pull new models
  - Allows exclusion of deprecated or irrelevant models via `exclude_pattern`
- Unified method interface:
  - `get_llm_models()` to fetch available models
  - `send_prompt()` to submit prompts and retrieve responses
- Optional Docker integration for local deployment (see below)

---

## 🧪 Quick Example

```r
library(llmModule)

# Create an LLM API object
api <- new_RemoteLlmApi("~/.secrets/openai.txt", provider = "OpenAI")

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

manager <- new_OllamaModelManager()
manager <- update(manager)

api <- new_LocalLlmApi(manager, "tinyllama")
prompt <- new_LlmPromptConfig(
  prompt_content = "Summarize entropy in one sentence.",
  model = "tinyllama:latest"
)

response <- new_LlmResponse(api, prompt)
response$generated_text
```

### Bridge Provider Example

```r
library(llmModule)

api <- new_BridgedLlmApi(
  provider = "Anthropic",
  api_key_path = "~/.secrets/anthropic.txt"
)

models <- get_llm_models(api)
```

---

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

----

## Notes for developers — local testing

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
