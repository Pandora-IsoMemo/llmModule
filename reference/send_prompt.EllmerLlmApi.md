# Send a prompt through the Ellmer bridge

Send a prompt through the Ellmer bridge

## Usage

``` r
# S3 method for class 'EllmerLlmApi'
send_prompt(api, prompt_config)
```

## Arguments

- api:

  An EllmerLlmApi object

- prompt_config:

  An LlmPromptConfig object

## Value

Normalized response with OpenAI-like
\`choices\[\[1\]\]\$message\$content\`
