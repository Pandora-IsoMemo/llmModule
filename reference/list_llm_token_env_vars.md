# List supported provider token environment variables

Returns the currently supported remote/bridge providers together with
the token environment variable name that \`llmModule\` resolves for each
provider.

## Usage

``` r
list_llm_token_env_vars()
```

## Value

A data frame with columns: \`provider\`, \`provider_key\`, and
\`token_env_var\`.
