# Generic LLM prompt sender This function is a generic method for sending prompts to a remote or local LLM API. It dispatches to the appropriate method based on the class of the \`api\` argument.

Generic LLM prompt sender This function is a generic method for sending
prompts to a remote or local LLM API. It dispatches to the appropriate
method based on the class of the \`api\` argument.

## Usage

``` r
send_prompt(api, prompt_config)
```

## Arguments

- api:

  An object of class RemoteLlmApi or LocalLlmApi, which contains the API
  key and URL for the remote LLM API.

- prompt_config:

  An object of class LlmPromptConfig, containing the prompt content and
  model parameters.
