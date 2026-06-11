#' Ask an LLM in one call
#'
#' Convenience wrapper that routes provider setup, prompt configuration, and
#' request dispatch through the package's existing API classes.
#'
#' @param provider Character provider name (e.g. "OpenAI", "DeepSeek",
#'   "Anthropic", "Ollama").
#' @param api_key Character API key string for remote/bridge providers.
#' @param model Optional character model identifier.
#' @param prompt_content Character prompt text.
#' @param api_key_path Deprecated path to a file containing an API key.
#' @param no_internet Logical runtime override for remote connectivity checks
#'   (legacy providers only).
#' @param exclude_pattern Character regex used to filter model lists.
#' @param base_url Character local Ollama base URL.
#' @param manager Optional `OllamaModelManager` object.
#' @param new_model Optional local model name to pull when using `provider = "Ollama"`.
#' @param ... Additional arguments forwarded to [new_LlmPromptConfig()].
#'
#' @return Character generated text on success. If an error occurs, returns an
#'   empty list with an `error` attribute containing the error message.
#' @export
ask_llm <- function(
  provider,
  api_key = NULL,
  model = NULL,
  prompt_content = NULL,
  api_key_path = NULL,
  no_internet = NULL,
  exclude_pattern = "",
  base_url = Sys.getenv("OLLAMA_BASE_URL", unset = "http://localhost:11434"),
  manager = NULL,
  new_model = "",
  ...
) {
  if (!is_valid_character(prompt_content)) {
    response <- list()
    attr(response, "error") <- "No valid prompt supplied. Use 'prompt_content'."
    return(response)
  }

  if (!is_valid_character(provider)) {
    response <- list()
    attr(response, "error") <- "No valid provider supplied."
    return(response)
  }

  provider <- trimws(provider)

  if (identical(provider, "Ollama")) {
    if (is.null(manager)) {
      api <- new_LocalLlmApi(
        new_model = new_model,
        base_url = base_url,
        exclude_pattern = exclude_pattern
      )
    } else {
      api <- new_LocalLlmApi(
        manager = manager,
        new_model = new_model,
        base_url = base_url,
        exclude_pattern = exclude_pattern
      )
    }
  } else {
    api <- new_BridgedLlmApi(
      provider = provider,
      api_key = api_key,
      api_key_path = api_key_path,
      no_internet = no_internet,
      exclude_pattern = exclude_pattern,
      model = model
    )
  }

  if (!is.null(attr(api, "error"))) {
    return(api)
  }

  prompt_args <- c(
    list(
      prompt_content = prompt_content,
      model = model
    ),
    list(...)
  )

  prompt_config <- do.call(new_LlmPromptConfig, prompt_args)
  if (!is.null(attr(prompt_config, "error"))) {
    return(prompt_config)
  }

  response <- new_LlmResponse(api, prompt_config)

  if (!is.null(attr(response, "error"))) {
    return(response)
  }

  if (!inherits(response, "LlmResponse") || !is_valid_character(response$generated_text)) {
    error_response <- list()
    attr(error_response, "error") <- "No generated text returned by provider."
    return(error_response)
  }

  # only return generated text
  response$generated_text
}