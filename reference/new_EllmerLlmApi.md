# Create an Ellmer bridge API object

Create an Ellmer bridge API object

## Usage

``` r
new_EllmerLlmApi(
  provider,
  api_key = NULL,
  api_key_path = NULL,
  model = NULL,
  exclude_pattern = ""
)
```

## Arguments

- provider:

  Character provider name.

- api_key:

  Character API key string.

- api_key_path:

  Deprecated file path to API key file.

- model:

  Character optional default model.

- exclude_pattern:

  Character regex for model exclusion.

## Value

An object of class \`EllmerLlmApi\` and \`LlmApi\`, or a list with
attribute \`error\` on failure.
