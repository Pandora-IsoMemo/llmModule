# Retrieve Available LLM Models via Ellmer bridge

Retrieve Available LLM Models via Ellmer bridge

## Usage

``` r
# S3 method for class 'EllmerLlmApi'
get_llm_models(x, with_creds_only = TRUE, ...)
```

## Arguments

- x:

  An EllmerLlmApi object

- with_creds_only:

  Logical, whether to attempt retrieval only if provider supports it
  with credentials.

- ...:

  Additional arguments

## Value

Character vector or named list of available models
