# llmModule (development version)

`llmModule` provides a structured and extensible R interface to interact
with both remote (e.g., OpenAI, DeepSeek) and local (via Ollama) Large
Language Model (LLM) APIs. It simplifies key workflows such as model
selection, prompt configuration, and request handling through a
consistent object-oriented interface.

`llmModule` provides a structured R interface for working with Large
Language Model (LLM) APIs, including
[OpenAI](https://platform.openai.com) and
[DeepSeek](https://platform.deepseek.com).

It simplifies interactions with chat-based LLMs by offering methods and
S3 classes for:

- API key management and validation
- Prompt configuration
- Sending chat prompts
- Extracting responses

## 🚀 Features

- Modular, object-oriented interface using S3 classes:
  - `RemoteLlmApi` for remote providers (OpenAI, DeepSeek)
  - `LocalLlmApi` for local Ollama servers
  - `LlmPromptConfig` to configure prompt messages and parameters
  - `LlmResponse` for structured handling of responses
- Comprehensive API validation:
  - Validates API key format, provider match, and key functionality via
    test request
  - Clear error reporting with automatic suggestion of likely provider
    mismatches
- Local model support (via [Ollama](https://ollama.com)):
  - Allows to pull new models
  - Allows exclusion of deprecated or irrelevant models via
    `exclude_pattern`
- Unified method interface:
  - [`get_llm_models()`](https://pandora-isomemo.github.io/llmModule/reference/get_llm_models.md)
    to fetch available models
  - [`send_prompt()`](https://pandora-isomemo.github.io/llmModule/reference/send_prompt.md)
    to submit prompts and retrieve responses
- Optional Docker integration for local deployment (see below)

------------------------------------------------------------------------

## 🧪 Quick Example

``` r
# Create an LLM API object
api <- new_RemoteLlmApi("~/.secrets/openai.txt", provider = "OpenAI")

# Set up a prompt
prompt <- new_LlmPromptConfig(
      model = "gpt-4.1",
      prompt_content = "What's the capital of Italy?"
)

# Send the prompt
result <- send_prompt(api, prompt)

# Extract the assistant's reply
result$choices[[1]]$message$content
```

------------------------------------------------------------------------

## 📦 Docker Installation (recommended)

Run this app in your browser with just one command! The Docker setup
includes all components — the `llmModule` Shiny frontend and the
`ollama` backend for local LLM model serving — no manual setup required.

### ✅ 1. Install the software Docker

Download installation files from one of the links below and follow
installation instructions:

- [Windows](https://docs.docker.com/desktop/windows/install/)
- [MacOS](https://docs.docker.com/desktop/install/mac-install/)
- [Linux](https://docs.docker.com/desktop/install/linux-install/)

After Docker is installed you can pull & run the app manually.

### 🚀 2. Run the App with Docker Compose

**Open a terminal (command line):**

- Windows command line:
  1.  Open the Start menu or press the `Windows key` + `R`;
  2.  Type cmd or cmd.exe in the Run command box;
  3.  Press Enter.
- MacOS: open the Terminal app.
- Linux: most Linux systems use the same default keyboard shortcut to
  start the command line: `Ctrl`-`Alt`-`T` or `Super`-`T`

To start the app you need the
[docker-compose.yaml](https://github.com/Pandora-IsoMemo/llmModule/blob/main/docker-compose.yml)
of this Repository. You can either:

**Run directly without cloning the repo:**

    curl -sL https://raw.githubusercontent.com/Pandora-IsoMemo/llmModule/refs/heads/main/docker-compose.yml | docker compose -f - up

**OR: Clone the repository and run in the project directory:**

    git clone https://github.com/Pandora-IsoMemo/llmModule.git
    cd llmModule
    docker compose up

These commands will:

1.  The first time you run this, it will download the necessary Docker
    images for
    - `ollama` (for model serving and its REST API) and
    - the `llm-module` (the Shiny web frontend that controls Ollama and
      can also interact with other LLM APIs like OpenAI, Deepseek).
2.  After images are pulled, a Docker network and a Docker volume will
    be created, and both container will start.
3.  The `llm-module` container hosts the application, which you can
    access in your web browser at `http://127.0.0.1:3838/`.

### 🚀 3. Run the app with a custom Ollama models path (optional)

To use your own pre-downloaded Ollama models, specify a custom path by
setting the `OLLAMA_LOCAL_MODELS_PATH` environment variable.

This requires cloning the repository and running Docker Compose from the
project directory.

``` bash
OLLAMA_LOCAL_MODELS_PATH=/path/to/your/models docker compose up
```

Default locations for Ollama models:

- linux: `/usr/share/ollama/.ollama`
- macOS: `~/.ollama`
- windows: `C:\\Users\\<username>\\.ollama`

This will mount your local models into the container for faster startup
and persistent access.

------------------------------------------------------------------------

## Notes for developers — local testing

To build and run the app locally:

``` bash
docker compose up --build
```

Use `--build` if:

- You made changes to source code or Dockerfiles,
- Or you’re testing a fresh environment.

To run with a custom models path:

``` bash
OLLAMA_LOCAL_MODELS_PATH=</path/to/your/models> docker compose up --build
```

*Tip:* Use `docker compose down` to stop and clean up the containers
when done.
