# Send a prompt to a local llm API (e.g., Ollama)

This function sends a prompt to the local LLM API (Ollama) and returns
the response in a structured format.

## Usage

``` r
# S3 method for class 'LocalLlmApi'
send_prompt(api, prompt_config)
```

## Arguments

- api:

  An object of class LocalLlmApi, which contains the URL and model name
  for the local LLM API.

- prompt_config:

  An object of class LlmPromptConfig, containing the prompt content and
  model parameters.

## Value

A list containing the response from the Ollama API, structured similarly
to OpenAI responses.

## See also

\[new_LlmResponse()\]
