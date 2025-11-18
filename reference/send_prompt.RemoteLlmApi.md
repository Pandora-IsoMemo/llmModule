# Send a prompt to a remote LLM API (e.g., OpenAI, DeepSeek) This function sends a prompt to the remote LLM API and returns the response in a structured format.

Send a prompt to a remote LLM API (e.g., OpenAI, DeepSeek) This function
sends a prompt to the remote LLM API and returns the response in a
structured format.

## Usage

``` r
# S3 method for class 'RemoteLlmApi'
send_prompt(api, prompt_config)
```

## Arguments

- api:

  An object of class RemoteLlmApi, which contains the API key and URL
  for the remote LLM API.

- prompt_config:

  An object of class LlmPromptConfig, containing the prompt content and
  model parameters.

## Value

A list containing the response from the LLM API, structured similarly to
OpenAI responses.

## See also

\[new_LlmResponse()\]
