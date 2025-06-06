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

### ✅ 2. Download and install docker image of the app

This image contains all elements necessary for you to run the app from a web
browser. Run this code in a local terminal 

**Open a terminal (command line):**

- Windows command line: 
   1. Open the Start menu or press the `Windows key` + `R`; 
   2. Type cmd or cmd.exe in the Run command box;
   3. Press Enter.
- MacOS: open the Terminal app.
- Linux: most Linux systems use the same default keyboard shortcut to start the
  command line: `Ctrl`-`Alt`-`T` or `Super`-`T`

**Copy paste the text below into the terminal and press Enter:**

```bash
docker pull ghcr.io/pandora-isomemo/llm-module:main
```

### 🚀 3. Run the application in Docker 

Steps 1 and 2 install the app. To run the app at any time after the installation
open a terminal (as described in point 2) copy paste the text below into the
terminal and press Enter. Wait for a notification that the app is in “listening”
mode.

```bash
docker run -p 3838:3838 ghcr.io/pandora-isomemo/llm-module:main
```

If the app is shutdown on Docker or if the terminal is closed the app will no
longer work in your web browser (see point 4).

### 🚀 4. Display the app in a web browser

Once the app is running in Docker you need to display it in a web browser. For
this, copy-paste the address below into your web browser’s address input and
press Enter.

```bash
http://127.0.0.1:3838/
```

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
