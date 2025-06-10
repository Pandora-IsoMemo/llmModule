# llmModule (development version)

<!-- badges: start -->
[![R-CMD-check](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

---

## 🧠 Docker Installation (recommended)

Run this app in your browser with just one command! The Docker setup includes all components — the 
`llm-module` Shiny frontend and the `ollama` backend for local LLM model serving — no manual setup required.

### ✅ 1. Install the software Docker

Download installation files from one of the links below and follow installation
instructions:

* [Windows](https://docs.docker.com/desktop/windows/install/)
* [MacOS](https://docs.docker.com/desktop/install/mac-install/)
* [Linux](https://docs.docker.com/desktop/install/linux-install/)

After Docker is installed you can pull & run the app manually.

### 🚀 2. Run the App with Docker Compose

**Open a terminal (command line):**

- Windows command line: 
   1. Open the Start menu or press the `Windows key` + `R`; 
   2. Type cmd or cmd.exe in the Run command box;
   3. Press Enter.
- MacOS: open the Terminal app.
- Linux: most Linux systems use the same default keyboard shortcut to start the
  command line: `Ctrl`-`Alt`-`T` or `Super`-`T`

To start the app you need the
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
    - the `llm-module` (the Shiny web frontend that controls Ollama and can also interact with other LLM APIs
   like OpenAI, Deepseek).
2. After images are pulled, a Docker network and a Docker volume will be created, and both container will start.
3. The `llm-module` container hosts the application, which you can access in your web browser at `http://127.0.0.1:3838/`.


### 🚀 3. Run the app with a custom Ollama models path (optional)

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


