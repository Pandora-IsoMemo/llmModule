#' Create and Validate Local LLM API Credentials
#'
#' @param manager An OllamaModelManager object
#' @param new_model Character, model name input from user (can be partial) of the model to pull
#' @param base_url Local Ollama base URL
#' @param pull_if_needed Logical, whether to pull the model automatically
#'
#' @return An object of class LocalLlmApi, or a list with an "error" attribute if construction fails.
#' @export
new_LocalLlmApi <- function(
    manager,
    new_model = "",
    base_url = Sys.getenv("OLLAMA_BASE_URL", unset = "http://localhost:11434"),
    pull_if_needed = TRUE
) {
  # TO DO: fix check, this check is not working yet...
  # if (!is_server_running(url = base_url)) {
  #   api <- list()
  #   attr(api, "error") <- "Ollama server does not appear to be running at the specified base URL."
  #   return(api)
  # }

  if (missing(manager)) {
    manager <- update(new_OllamaModelManager())
  }

  if (!inherits(manager, "OllamaModelManager")) {
    api <- list()
    attr(api, "error") <- "You must provide a valid OllamaModelManager object."
    return(api)
  }

  if (!is.null(new_model) && new_model != "") {
    model_clean <- clean_model_name(manager, new_model)

    res <- pull_model_if_needed(manager, model_clean)
    manager <- res$manager
    model_obj <- res$model

    if (model_obj$status == "error") {
      api <- list()
      attr(api, "error") <- sprintf("Failed to pull model '%s': %s", model_clean, model_obj$message)
      return(api)
    }
  }

  api <- structure(
    list(
      url = base_url,
      provider = "ollama",
      manager = manager
    ),
    class = c("LocalLlmApi", "LlmApi")
  )

  if (!is.null(new_model) && new_model != "" && model_obj$status == "ready") {
    attr(api, "message") <- sprintf("Model '%s' is already ready.", model_clean)
  }

  return(api)
}

#' Print method for LocalLlmApi
#'
#' @param x An LocalLlmApi object
#' @param ... Additional arguments
#'
#' @export
print.LocalLlmApi <- function(x, ...) {
  cat("Local LLM API Credentials\n")
  cat("Provider:", x$provider, "\n")
  cat("Endpoint:", x$url, "\n")
}


#' Retrieve Available LLM Models
#'
#' The get_llm_models() method fetches a list of available models from the local Ollama
#' Large Language Model (LLM) API.
#' It requires an LocalLlmApi object and returns the available models.
#'
#' @param x An object of class LocalLlmApi
#' @param ... Additional arguments
#'
#' @return A response object containing a list of available models from the selected API.
#'
#' @export
get_llm_models.LocalLlmApi <- function(x, ...) {
  local_models <- x$manager$local_models

  # Extract categories
  categories <- vapply(local_models, function(x) categorize_model(x), character(1))
  models <- vapply(local_models, function(x) x, character(1))
  models_list <- extract_named_model_list(models, categories)

  return(models_list)
}
