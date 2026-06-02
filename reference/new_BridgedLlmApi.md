# Create a provider-routed LLM API object

\`new_BridgedLlmApi()\` is a routing constructor that keeps legacy
providers (\`OpenAI\`, \`DeepSeek\`) on \`RemoteLlmApi\` and uses
\`EllmerLlmApi\` as a bridge for all other providers.

## Usage

``` r
new_BridgedLlmApi(
  provider,
  api_key = NULL,
  api_key_path = NULL,
  no_internet = NULL,
  exclude_pattern = "",
  model = NULL
)
```

## Arguments

- provider:

  Character provider name.

- api_key:

  Character API key string.

- api_key_path:

  Deprecated file path to API key file.

- no_internet:

  Logical, passed through to \`new_RemoteLlmApi()\` for legacy
  providers.

- exclude_pattern:

  Character regex for model exclusion.

- model:

  Character optional default model for bridged providers.

## Value

An object of class \`RemoteLlmApi\` (for \`OpenAI\`/\`DeepSeek\`) or
\`EllmerLlmApi\` + \`LlmApi\` (for all other providers).
