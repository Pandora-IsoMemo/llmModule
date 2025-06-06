# llmModule (development version)

<!-- badges: start -->
[![R-CMD-check](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Pandora-IsoMemo/llmModule/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

---

## 🧠 Ollama Setup (Optional)

This app depends on [Ollama](https://ollama.com) to run **local** large language models like LLaMA 3, Mistral, or Gemma. Follow the steps below to install and run Ollama on your system if you'd like to use a local model in addition to cloud providers such as OpenAI or DeepSeek.

### ✅ 1. Install Ollama

#### Linux

Run the official install script:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### macOS

Install via [Homebrew](https://brew.sh):

```bash
brew install ollama
```

#### Windows

Download and run the installer from the [Ollama for Windows page](https://ollama.com/download).

For full platform details, see the [official installation guide](https://ollama.com/download).

---

### 🚀 2. Start the Ollama Service

Start the Ollama backend by running:

```bash
ollama serve
```

On Linux, to enable it as a persistent background service:

```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

On macOS, Ollama should automatically run in the background after installation.

On Windows, the Ollama service will run automatically after installation.

---

## 🧠 Docker Installation (recommended)

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

The docker compose has everything you need to run app directly from your web browser. To start the app you 
need the [docker-compose.yaml](https://github.com/Pandora-IsoMemo/llmModule/blob/main/docker-compose.yml) of this
Repository. You can clone the entire Repository and use `docker compuse up` or simply run the following command:

```
curl -sL https://raw.githubusercontent.com/Pandora-IsoMemo/llmModule/refs/heads/main/docker-compose.yml | docker compose -f - up
```

Both commands will perform the following actions::

1. The first time you run this, it will download the necessary Docker images for `ollama` (for model serving and its 
   REST API) and the `llm-module` (the SHiny web frontend that controls Ollama and can also interact with other LLM APIs
   like OpenAI, Deepseek, etc.).
2. After images are pulled, a Docker network and a Docker volume will be created, and both container will start.
3. The `llm-module` container host the application, which you can access in your web browser at `http://127.0.0.1:3838/`.

----

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
