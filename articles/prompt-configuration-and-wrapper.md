# Prompt Configuration and Wrapper Usage

This vignette explains:

- How to discover providers and models
- Which prompt arguments are available
- How to call models with either the low-level API objects or the
  one-call wrapper
  [`ask_llm()`](https://pandora-isomemo.github.io/llmModule/reference/ask_llm.md)
- How to handle common runtime errors

## 1) Choose a Provider and Model

Use provider and model discovery before sending prompts.

``` r

library(llmModule)

providers <- get_providers()
providers

api <- new_BridgedLlmApi(
  provider = "OpenAI",
  api_key = Sys.getenv("OPENAI_TOKEN")
)

models <- get_llm_models(api)
models
```

For local usage with Ollama:

``` r

manager <- new_OllamaModelManager()
manager <- update(manager)

local_api <- new_LocalLlmApi(manager, "tinyllama")
get_llm_models(local_api)
```

## 2) Prompt Arguments You Can Use

[`ask_llm()`](https://pandora-isomemo.github.io/llmModule/reference/ask_llm.md)
forwards extra arguments (`...`) directly to
[`new_LlmPromptConfig()`](https://pandora-isomemo.github.io/llmModule/reference/new_LlmPromptConfig.md).

Core prompt arguments:

- `prompt_content` (required): user prompt text
- `model` (required): model id to call
- `prompt_role`: role for the message (default `"user"`)
- `max_tokens`: max generated tokens (default `100`)
- `temperature`: randomness (default `1.0`)
- `top_p`: nucleus sampling value (default `1`)
- `n`: number of completions (default `1`)
- `stop`: stop sequence(s)
- `seed`: optional numeric seed
- `presence_penalty`: topic novelty bias (default `0`)
- `frequency_penalty`: repetition penalty (default `0`)
- `logprobs`: include token log-probabilities (default `FALSE`)

Note:

- Not every provider/model combination supports every argument.
- If `temperature = 0` and `n > 1`, `n` is forced to `1` to avoid
  unnecessary token usage.

## 3) Authentication and Token Resolution

For remote/bridge providers, `llmModule` resolves credentials in this
order:

1.  `api_key` argument
2.  Provider token environment variable via internal
    `get_token_for_provider(provider)`

Common provider token variables:

- `OPENAI_TOKEN`
- `DEEPSEEK_TOKEN`
- `ANTHROPIC_TOKEN`
- `GITHUB_TOKEN`
- `OPENROUTER_TOKEN`
- `GROQ_TOKEN`
- `MISTRAL_TOKEN`

Fallback pattern for other provider keys: `PROVIDER_KEY_TOKEN`.

Example `.Renviron` setup:

``` r

# OPENAI_TOKEN=your-openai-token
# ANTHROPIC_TOKEN=your-anthropic-token
# GITHUB_TOKEN=your-github-token
```

## 4) One-call Usage with `ask_llm()`

[`ask_llm()`](https://pandora-isomemo.github.io/llmModule/reference/ask_llm.md)
is the fastest path for scripts and simple package workflows.

``` r

result <- ask_llm(
  provider = "OpenAI",
  api_key = Sys.getenv("OPENAI_TOKEN"),
  model = "gpt-4.1",
  prompt_content = "Summarize entropy in one sentence.",
  temperature = 0.2,
  max_tokens = 80,
  top_p = 1,
  n = 1
)

if (!is.null(attr(result, "error"))) {
  message(attr(result, "error"))
} else {
  result$generated_text
}
```

For local Ollama with the wrapper:

``` r

local_result <- ask_llm(
  provider = "Ollama",
  model = "tinyllama:latest",
  prompt_content = "Summarize entropy in one sentence.",
  temperature = 0.2
)
```

## 5) Object-based Usage (Low-level Control)

Use this approach when you want explicit API and prompt objects.

``` r

api <- new_BridgedLlmApi(
  provider = "Anthropic",
  api_key = Sys.getenv("ANTHROPIC_TOKEN")
)

prompt <- new_LlmPromptConfig(
  model = "claude-3-5-sonnet-latest",
  prompt_content = "Write three bullet points on entropy.",
  temperature = 0.3,
  max_tokens = 120
)

result <- send_prompt(api, prompt)

# or rely on token env var resolution directly
api_auto <- new_BridgedLlmApi(provider = "Anthropic")
```

## 6) Error Handling Pattern

Network, credential, and provider errors are attached via the `error`
attribute.

``` r

result <- ask_llm(
  provider = "OpenAI",
  api_key = "invalid-key",
  model = "gpt-4.1",
  prompt_content = "Hello"
)

if (!is.null(attr(result, "error"))) {
  message("Request failed: ", attr(result, "error"))
} else {
  cat(result$generated_text)
}
```

## 7) Recommended Workflow

- Start with
  [`get_providers()`](https://pandora-isomemo.github.io/llmModule/reference/get_providers.md)
  to discover available providers in your environment.
- Create an API object and call
  [`get_llm_models()`](https://pandora-isomemo.github.io/llmModule/reference/get_llm_models.md)
  to pick a valid model.
- Use
  [`ask_llm()`](https://pandora-isomemo.github.io/llmModule/reference/ask_llm.md)
  for concise one-call usage.
- Switch to explicit objects (`new_*` +
  [`send_prompt()`](https://pandora-isomemo.github.io/llmModule/reference/send_prompt.md))
  when you need finer control.
