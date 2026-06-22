# Retrieve Available LLM Models plus metadata via Ellmer bridge

Retrieve Available LLM Models plus metadata via Ellmer bridge

## Usage

``` r
# S3 method for class 'EllmerLlmApi'
get_llm_models_info(x, with_creds_only = TRUE, ...)
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

A \`LlmModelsInfo\` object with \`models\` and selection metadata.
