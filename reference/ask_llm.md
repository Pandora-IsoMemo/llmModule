# Ask an LLM in one call

Convenience wrapper that routes provider setup, prompt configuration,
and request dispatch through the package's existing API classes.

## Usage

``` r
ask_llm(
  provider,
  api_key = NULL,
  model = NULL,
  prompt_content = NULL,
  api_key_path = NULL,
  no_internet = NULL,
  exclude_pattern = "",
  base_url = Sys.getenv("OLLAMA_BASE_URL", unset = "http://localhost:11434"),
  manager = NULL,
  new_model = "",
  ...
)
```

## Arguments

- provider:

  Character provider name (e.g. "OpenAI", "DeepSeek", "Anthropic",
  "Ollama").

- api_key:

  Character API key string for remote/bridge providers.

- model:

  Optional character model identifier.

- prompt_content:

  Character prompt text.

- api_key_path:

  Deprecated path to a file containing an API key.

- no_internet:

  Logical runtime override for remote connectivity checks (legacy
  providers only).

- exclude_pattern:

  Character regex used to filter model lists.

- base_url:

  Character local Ollama base URL.

- manager:

  Optional \`OllamaModelManager\` object.

- new_model:

  Optional local model name to pull when using \`provider = "Ollama"\`.

- ...:

  Additional arguments forwarded to \[new_LlmPromptConfig()\].

## Value

Character generated text on success. If an error occurs, returns an
empty list with an \`error\` attribute containing the error message.
