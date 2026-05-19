# Test Ollama Server Connection

Checks if the local Ollama server is running and reachable.

## Usage

``` r
is_ollama_running(url = Sys.getenv("OLLAMA_BASE_URL"))
```

## Arguments

- url:

  Character string of the Ollama server URL. Defaults to the value of
  the OLLAMA_BASE_URL environment variable.

## Value

Logical TRUE if server is running, FALSE otherwise.
