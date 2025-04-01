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
      err_msg <- sprintf("API key does not match the selected provider. It appears to be for '%s'.", other_provider)
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
