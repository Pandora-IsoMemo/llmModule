# Extract and format LLM response as a table

Extract and format LLM response as a table

## Usage

``` r
# S3 method for class 'LlmResponse'
as_table(x, output_type = c("text", "meta", "logprobs", "complete"), ...)
```

## Arguments

- x:

  An LlmResponse object

- output_type:

  A character string indicating the type of output to format. Possible
  values are "text", "meta", "logprobs", or "complete".

- ...:

  Additional arguments (not used)

## Value

A formatted character string
