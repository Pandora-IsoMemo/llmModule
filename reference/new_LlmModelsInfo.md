# LlmModelsInfo class

This class encapsulates information about available LLM models from a
provider, including metadata about model selection and fallback
behavior.

## Usage

``` r
new_LlmModelsInfo(
  models = list(),
  can_fallback_to_provider_default = FALSE,
  listing_status = c("ok", "empty", "error", "unavailable"),
  provider = NULL
)
```

## Arguments

- models:

  A character vector or named list of available models.

- can_fallback_to_provider_default:

  Logical indicating if selecting no explicit model can fall back to a
  provider default.

- listing_status:

  Character indicating the status of the model listing (e.g., "ok",
  "empty", "error", "unavailable").

- provider:

  Character name of the provider.
