#' Create and Validate LLM API Credentials
#'
#' The new_LlmApi() function constructs an S3 object that stores API credentials for interacting
#' with Large Language Models (LLMs) such as OpenAI's GPT models and DeepSeek models.
#' It reads the API key from a specified file, validates its format, ensures it matches the correct provider,
#' and checks if the key is valid by performing a test request.
#'
#' @param api_key_path character string specifying the path to a file containing the API key.
#' @param provider character string specifying the provider for the API key. Must be either "OpenAI" or "DeepSeek".
#'
#' @return An object of class LlmApi, containing the API key, URL, and provider name (either "OpenAI" or "DeepSeek").
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
#' api <- new_LlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
#'
#' # Create API credentials for DeepSeek
#' api <- new_LlmApi(api_key_path = "path/to/deepseek_key.txt", provider = "DeepSeek")
#'
#' # Print the API object
#' print(api)
#' }
#' @export
new_LlmApi <- function(api_key_path, provider) {
  provider <- match.arg(provider, c("OpenAI", "DeepSeek"))

  # Early checks
  if (!file.exists(api_key_path)) {
    api <- list()
    attr(api, "error") <- "API key file does not exist."
    return(api)
  }

  api_key <- trimws(readLines(api_key_path, warn = FALSE))

  # Determine expected provider from key pattern
  key_provider <- if (grepl("^sk-", api_key)) {
    "OpenAI"
  } else if (grepl("^[a-zA-Z0-9]+$", api_key)) {
    "DeepSeek"
  } else {
    api <- list()
    attr(api, "error") <- sprintf("Unknown API key format. Ensure you are using a valid key for the provider '%s'.", provider)
    return(api)
  }

  if (nchar(api_key) < 20) {
    api <- list()
    attr(api, "error") <- "API key appears too short."
    return(api)
  }

  # Ensure API key matches the correct provider
  if (provider != key_provider) {
    api <- list()
    attr(api, "error") <- sprintf("API key appears to be for '%s', but '%s' was selected.", key_provider, provider)
    return(api)
  }

  # Define API URL
  url <- switch(
    provider,
    "OpenAI" = "https://api.openai.com/v1/chat/completions",
    "DeepSeek" = "https://api.deepseek.com/v1/completion"
  )

  # Validate key with test request
  is_valid <- tryCatch(
    validate_api_key(api_key, url, provider),
    error = function(e) e
  )

  if (inherits(is_valid, "error")) {
    api <- list()
    attr(api, "error") <- is_valid$message
    return(api)
  }

  if (!is_valid) {
    api <- list()
    attr(api, "error") <- "API key failed validation request."
    return(api)
  }

  api_obj <- structure(
    list(api_key = api_key, url = url, provider = provider),
    class = "LlmApi"
  )
  return(api_obj)
}

#' Print method for LlmApi
#'
#' @param x An LlmApi object
#' @param ... Additional arguments
#'
#' @export
print.LlmApi <- function(x, ...) {
  cat("LLM API Credentials\n")
  cat("Provider:", x$provider, "\n")
  cat("API Key: [hidden]\n")
  cat("Endpoint:", x$url, "\n")
}


# Function to validate API key via a test request
validate_api_key <- function(api_key, url, provider) {
  # Set test model based on provider
  test_model <- if (provider == "OpenAI") "gpt-3.5-turbo" else "deepseek-chat"

  test_req <- request(url) |>
    req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(list(model = test_model, messages = list(list(role = "user", content = "Hello"))))

  res <- req_perform(test_req)  # Let error propagate

  return(!is.null(res) && res$status_code == 200)
}
