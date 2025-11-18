# Retrieve Available LLM Models

The get_llm_models() method fetches a list of available models from a
specified remote Large Language Model (LLM) API, such as OpenAI's GPT
models or DeepSeek models. It requires an RemoteLlmApi object for
authentication and returns the available model options.

## Usage

``` r
# S3 method for class 'RemoteLlmApi'
get_llm_models(x, ...)
```

## Arguments

- x:

  An object of class RemoteLlmApi

- ...:

  Additional arguments

## Value

A response object containing a list of available models from the
selected API. This includes model IDs, descriptions, and other metadata.

## Details

This function allows users to dynamically query OpenAI and DeepSeek to
determine which models are accessible while ensuring valid
authentication via the LlmApi class.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create API credentials for DeepSeek
api <- new_RemoteLlmApi(api_key_path = "path/to/deepseek_key.txt", provider = "DeepSeek")

# Retrieve available models from DeepSeek
models <- get_llm_models(api)

# Create API credentials for OpenAI
api <- new_RemoteLlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")

# Retrieve available models from OpenAI
models <- get_llm_models(api)
} # }
```
