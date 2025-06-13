# llmModule 25.06.1

## New features

* add options to enable integration of `llm_generate_prompt` shiny module into the import module of the `DataTools` package (#3)

# llmModule 25.06.0

## New features

* Added option to use LLM models from a local installation of Ollama:

  * New classes `LocalLlmApi`, `OllamaModel`, and `OllamaModelManager` provide support for model configuration, and response parsing using locally hosted models.
  * The `llm_api_ui/server`, `llm_prompt_config_ui/server` and `llm_generate_prompt_ui/server` functions now detect and support Ollama-based backends.

## Bug fixes

* Fixed issue where the 'Generate Text' button remained enabled even when no valid API key was configured.


# llmModule 25.04.0

## New features

* added method to format the API response (#1)

# llmModule 0.1.0

## New features

* first draft of the llm module

