# Get eligible ellmer providers

Returns a data frame of providers with their chat function, models
helper function (if available), auth argument capabilities, and model
argument rules. Only providers with a chat \`credentials\` argument are
included. Providers that require an explicit model must also provide a
models helper.

## Usage

``` r
eligible_ellmer_providers()
```

## Value

A data frame with columns: provider_key, chat_function, models_function,
model_rule, has_models_helper
