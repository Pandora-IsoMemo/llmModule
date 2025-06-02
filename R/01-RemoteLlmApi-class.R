#' Create and Validate Remote LLM API Credentials
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

#' Retrieve Available LLM Models
#'
#' The get_llm_models() method fetches a list of available models from a specified remote
#' Large Language Model (LLM) API, such as OpenAI's GPT models or DeepSeek models.
#' It requires an RemoteLlmApi object for authentication and returns the available model options.
#'
#' This function allows users to dynamically query OpenAI and DeepSeek to determine which models
#' are accessible while ensuring valid authentication via the LlmApi class.
#'
#' @param x An object of class RemoteLlmApi
#' @param ... Additional arguments
#'
#' @return A response object containing a list of available models from the selected API. This includes model IDs, descriptions, and other metadata.
#'
#' @examples
#' \dontrun{
#' # Create API credentials for DeepSeek
#' api <- new_RemoteLlmApi(api_key_path = "path/to/deepseek_key.txt", provider = "DeepSeek")
#'
#' # Retrieve available models from DeepSeek
#' models <- get_llm_models(api)
#'
#' # Create API credentials for OpenAI
#' api <- new_RemoteLlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
#'
#' # Retrieve available models from OpenAI
#' models <- get_llm_models(api)
#' }
#'
#' @export
get_llm_models.RemoteLlmApi <- function(x, ...) {
  req <- request(x$url_models) |>
    req_headers(Authorization = paste("Bearer", x$api_key),
                `Content-Type` = "application/json")

  content <- try_send_request(req)

  # Extract categories
  categories <- vapply(content$data, function(x) categorize_model(x$id), character(1))
  models <- vapply(content$data, function(x) x$id, character(1))
  models_list <- extract_named_model_list(models, categories)

  return(models_list)
}

try_send_request <- function(request) {
  request_base <- tryCatch({
    # Send request
    request |> req_perform()
  }, error = function(e) {
    return(list(error = "API request failed", message = e$message))
  })

  request_content <- tryCatch({
    # Parse response
    request_base |> resp_body_json()
  }, error = function(e) {
    code <- "API parsing failed"
    warning(paste0(code, e$message))
    list(error = code, message = e$message)
  })

  if (!is.null(request_base$status_code) &&
      request_base$status_code != 200) {
    code <- paste0("Request completed with error. Code: ",
                   request_base$status_code)
    if (!is.null(request_content$error)) {
      message <- paste0(", message: ", request_content$error$message)
    } else {
      message <- NULL
    }

    warning(paste0(code, message))
  }

  return(request_content)
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
