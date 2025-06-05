# llmModule 25.06.0

## New features

* Added option to use LLM models from a local installation of Ollama:

  * New classes `OllamaApi`, `OllamaPromptConfig`, and `OllamaResponse` provide support for model configuration, prompt handling, and response parsing using locally hosted models.
  * The `llm_api_ui/server` and `llm_prompt_config_ui/server` functions now detect and support Ollama-based backends.

* New `llm_generate_prompt_ui/server` module:

  * Provides a simple ACE-editor-based interface to test prompts interactively.
  * Includes status display and response output option.

## Improvements

* Enhanced status messaging in `statusMessageServer` to distinguish between incomplete and failed responses.
* Improved modularity and reusability of UI components (`llm_api_ui`, `llm_prompt_config_ui`).

## Bug fixes

* Fixed issue where the 'Generate Text' button remained enabled even when no valid API key was configured.


# llmModule 25.04.0

## New features

* added method to format the API response (#1)

# llmModule 0.1.0

## New features

* first draft of the llm module

