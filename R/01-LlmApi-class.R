#' Create and Validate LLM API Credentials
# REMOTE LLM API ----

#'
#' The new_RemoteLlmApi() function constructs an S3 object that stores API credentials for interacting
#' with Large Language Models (LLMs) such as OpenAI's GPT models and DeepSeek models.
#' It reads the API key from a specified file, validates its format, ensures it matches the correct provider,
#' and checks if the key is valid by performing a test request.
#'
#' @param api_key_path character string specifying the path to a file containing the API key.
#' @param provider character string specifying the provider for the API key. Must be either "OpenAI" or "DeepSeek".
#'
#' @return An object of class RemoteLlmApi, containing the API key, URL, and provider name
#'  (either "OpenAI" or "DeepSeek"), or a list with an "error" attribute if construction fails.
#'
#' @details
#' This function includes multiple validation steps:
#' - Reads the API key from the specified file.
#' - Ensures the API key format is correct (e.g., OpenAI keys start with "sk-" and DeepSeek keys contain alphanumeric characters).
#' - Matches the API key to the correct provider.
#' - Prevents incorrect combinations of API keys and providers.
#' - Sends a test request to verify that the API key is active and functional.
#'
#' If any of these checks fail, an error is returned with details about the issue.
#'
#' @examples
#' \dontrun{
#' # Create API credentials for OpenAI
#' api <- new_RemoteLlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
#'
#' # Create API credentials for DeepSeek
#' api <- new_RemoteLlmApi(api_key_path = "path/to/deepseek_key.txt", provider = "DeepSeek")
#'
#' # Print the API object
#' print(api)
#' }
#' @export
new_RemoteLlmApi <- function(api_key_path, provider) {
  provider <- match.arg(provider, c("OpenAI", "DeepSeek"))

  if (missing(api_key_path) || !is.character(api_key_path) || nchar(api_key_path) == 0) {
    api <- list()
    attr(api, "error") <- "No valid API key path."
    return(api)
  }

  # Early checks
  if (!file.exists(api_key_path)) {
    api <- list()
    attr(api, "error") <- "API key file does not exist."
    return(api)
  }

  api_key <- trimws(readLines(api_key_path, warn = FALSE))

  if (nchar(api_key) < 20) {
    api <- list()
    attr(api, "error") <- "API key appears too short."
    return(api)
  }

  # Define API URL
  url <- c(
    "OpenAI" = "https://api.openai.com/v1/chat/completions",
    "DeepSeek" = "https://api.deepseek.com/v1/chat/completions"
  )

  url_models <- c(
    "OpenAI" = "https://api.openai.com/v1/models",
    "DeepSeek" = "https://api.deepseek.com/v1/models"
  )

  # Validate the key for selected provider with a request to the models endpoint
  is_valid <- tryCatch(
    validate_api_key(api_key, url_models[provider]),
    error = function(e) e
  )

  if (inherits(is_valid, "error")) {
    # set error message
    err_msg <- is_valid$message

    # test the other provider
    other_provider <- ifelse(provider == "OpenAI", "DeepSeek", "OpenAI")

    is_valid_other <- tryCatch(
      validate_api_key(api_key, url_models[other_provider]),
      error = function(e) e
    )

    if (!inherits(is_valid_other, "error")) {
      # update error message
      err_msg <-
        sprintf("API key does not match the selected provider. It appears to be for '%s'.", other_provider)
    }

    api <- list()
    attr(api, "error") <- err_msg
    return(api)
  }

  if (!is_valid) {
    # if invalid but error message is missing
    api <- list()
    attr(api, "error") <- "API key failed validation request."
    return(api)
  }

  api_obj <- structure(
    list(api_key = api_key, provider = provider, url = url[provider], url_models = url_models[provider]),
    class = c("RemoteLlmApi", "LlmApi")
  )
  return(api_obj)
}

#' Print method for RemoteLlmApi
#'
#' @param x An RemoteLlmApi object
#' @param ... Additional arguments
#'
#' @export
print.RemoteLlmApi <- function(x, ...) {
  cat("Remote LLM API Credentials\n")
  cat("Provider:", x$provider, "\n")
  cat("API Key: [hidden]\n")
  cat("Endpoint:", x$url, "\n")
  cat("Models URL:", x$url_models, "\n")
}

# Function to validate API key via a test request
validate_api_key <- function(api_key, url_models) {
  test_req <- request(url_models) |>
    req_headers(Authorization = paste("Bearer", api_key))

  res <- req_perform(test_req)

  if (!is.null(res) && !is.null(res$status_code) && res$status_code != 200) {
    stop(res$status_code)
  }

  return(!is.null(res) && res$status_code == 200)
}

# LOCAL LLM API ----

#' Create a local LLM API object from model name and manager
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
