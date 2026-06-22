# Get providers for selection

Returns a named character vector of provider keys with user-friendly
names. The list is constructed based on legacy providers, eligible
Ellmer providers, and whether Ollama is available.

## Usage

``` r
get_providers(ollama_available = NULL)
```

## Arguments

- ollama_available:

  Logical, whether Ollama is available in the current environment.

## Value

Named character vector of provider keys with user-friendly names.
