# Retrieve Available LLM Models

The get_llm_models() method fetches a list of available models from the
local Ollama Large Language Model (LLM) API. It requires an LocalLlmApi
object and returns the available models.

## Usage

``` r
# S3 method for class 'LocalLlmApi'
get_llm_models(x, ...)
```

## Arguments

- x:

  An object of class LocalLlmApi

- ...:

  Additional arguments

## Value

A response object containing a list of available models from the
selected API.
