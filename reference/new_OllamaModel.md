# Create an Ollama Model Object

Constructs an S3 object representing a single Ollama model, including
its name and status (e.g., ready, pulled, error).

## Usage

``` r
new_OllamaModel(model_name, status = "ready", message = NULL)
```

## Arguments

- model_name:

  Character string, the model's name

- status:

  Character string, model status ("ready", "pulled", "error")

- message:

  Optional character string, error message if any

## Value

An object of class OllamaModel
