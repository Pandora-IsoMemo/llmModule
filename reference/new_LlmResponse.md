# Create and Structure LLM Response Object

The new_LlmResponse() function sends a prompt to a Large Language Model
(LLM) API and returns a structured response object. It integrates the
credentials from an LlmApi object and the prompt configuration from an
LlmPromptConfig object, handles request errors gracefully, and returns
the model-generated content along with associated metadata.

## Usage

``` r
new_LlmResponse(api, prompt_config)
```

## Arguments

- api:

  An object of class RemoteLlmApi or LocalLlmApi.

- prompt_config:

  An object of class LlmPromptConfig, containing prompt content, model,
  and tuning parameters (e.g., temperature, max tokens).

## Value

An object of class LlmResponse, which includes the following components:

\- content: The raw API response returned from the model. - provider:
The name of the API provider (e.g., "OpenAI", "DeepSeek"). -
prompt_config: The unclassed list representation of the original prompt
settings. - generated_text: The primary response text content from the
model.

If an error occurs during validation or request sending, an empty list
is returned with an error attribute containing the error message.

## See also

\[new_RemoteLlmApi()\], \[new_LlmPromptConfig()\]\]

## Examples

``` r
api <- new_RemoteLlmApi(api_key_path = "path/to/key.txt", provider = "OpenAI")
prompt <- new_LlmPromptConfig(
  prompt_content = "Explain entropy in simple terms.",
  model = "gpt-3.5-turbo",
  temperature = 0.7
)
response <- new_LlmResponse(api, prompt)

if (!is.null(attr(response, "error"))) {
  cat("Error:", attr(response, "error"), "\n")
} else {
  cat("Model response:", response$generated_text, "\n")
}
#> Error: LLM API not valid, must be an RemoteLlmApi or LocalLlmApi object. 
```
