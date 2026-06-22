# Create an empty LlmModelsInfo object

This function creates an LlmModelsInfo object with an empty model list
and specified provider and listing status.

## Usage

``` r
new_empty_LlmModelsInfo(provider = NULL, listing_status = "empty")
```

## Arguments

- provider:

  Character name of the provider (optional).

- listing_status:

  Character indicating the status of the model listing (default is
  "empty").

## Value

An LlmModelsInfo object with no models and specified metadata.
