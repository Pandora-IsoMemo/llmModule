# Create and Validate Local LLM API Credentials

Create and Validate Local LLM API Credentials

## Usage

``` r
new_LocalLlmApi(
  manager,
  new_model = "",
  base_url = Sys.getenv("OLLAMA_BASE_URL", unset = "http://localhost:11434"),
  exclude_pattern = ""
)
```

## Arguments

- manager:

  An OllamaModelManager object

- new_model:

  Character, model name input from user (can be partial) of the model to
  pull

- base_url:

  Local Ollama base URL

- exclude_pattern:

  Character, a regex pattern to exclude certain models from the list of
  available models, e.g.
  "babbage\|curie\|dall-e\|davinci\|text-embedding\|tts\|whisper"

## Value

An object of class LocalLlmApi, or a list with an "error" attribute if
construction fails.
