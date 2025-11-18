# Create and Manage LLM Prompt Settings

The new_LlmPromptConfig() function constructs an S3 object that stores
the parameters required for making requests to Large Language Models
(LLMs) such as OpenAI's GPT models and DeepSeek models.

## Usage

``` r
new_LlmPromptConfig(
  prompt_content,
  model,
  max_tokens = 100,
  temperature = 1,
  prompt_role = "user",
  seed = NULL,
  top_p = 1,
  n = 1,
  stop = NULL,
  presence_penalty = 0,
  frequency_penalty = 0,
  logprobs = FALSE
)
```

## Arguments

- prompt_content:

  character string containing the primary instruction or query for the
  model. This serves as the main input to the LLM.

- model:

  Character string specifying the model to use (e.g., \`'gpt-4.1'\` for
  OpenAI or \`'deepseek-chat'\` for DeepSeek). To retrieve a list of
  valid models for each LLM, use the
  [`get_llm_models()`](https://pandora-isomemo.github.io/llmModule/reference/get_llm_models.md)
  method

  See the following documentation for valid models: - [OpenAI model
  list](https://platform.openai.com/docs/models) - [DeepSeek model
  list](https://api-docs.deepseek.com/api/list-models)

- max_tokens:

  numeric (default: 100) defining the maximum number of tokens to be
  generated in the response.

- temperature:

  numeric (default: 1.0) controlling randomness in responses. Lower
  values (e.g., 0.2) make responses deterministic, while higher values
  (e.g., 1.5) increase creativity.

- prompt_role:

  character (default: 'user') specifying the role of the message. Common
  values include 'system', 'assistant', and 'user'.

- seed:

  numeric (optional) for controlling reproducibility. If NULL, no seed
  is set.

- top_p:

  numeric (default: 1) alternative to temperature, specifying nucleus
  sampling probability. A value of 0.1 considers only the top 10%
  probability mass.

- n:

  numeric (default: 1) defining the number of responses to generate per
  request. If temperature is 0, n is automatically set to 1.

- stop:

  character or character vector (default: NULL) defining stop sequences
  for response termination. Up to 4 sequences can be specified.

- presence_penalty:

  numeric (default: 0) between -2.0 and +2.0, influencing model
  inclination to introduce new topics.

- frequency_penalty:

  numeric (default: 0) between -2.0 and +2.0, influencing model tendency
  to repeat words or phrases.

- logprobs:

  boolean (default: FALSE) specifying whether to return log
  probabilities for output tokens.

## Value

An object of class LlmPromptConfig, containing all specified parameters
in a structured format.

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve available models
api <- new_RemoteLlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
models <- get_llm_models(api)
} # }

# Create a parameter object for OpenAI GPT-4.1
params <- new_LlmPromptConfig(
  prompt_content = 'Explain entropy in simple terms.',
  model = 'gpt-4.1',
  temperature = 0.7,
  max_tokens = 150
)

# Create a parameter object for DeepSeek
params <- new_LlmPromptConfig(
  prompt_content = 'What are three innovative AI research topics?',
  model = 'deepseek-chat',
  temperature = 0.9,
  n = 3
)

# Print the parameter object
print(params)
#> LLM Promp Settings
#> Model: deepseek-chat 
#> Prompt Role: user 
#> Prompt Content: What are three innovative AI research topics? 
#> Max Tokens: 100 
#> Temperature: 0.9 
#> Top-P: 1 
#> N: 3 
```
