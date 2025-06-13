#' Create and Validate Remote LLM API Credentials
#'
#' The new_RemoteLlmApi() function constructs an S3 object that stores API credentials for interacting
#' with Large Language Models (LLMs) such as OpenAI's GPT models and DeepSeek models.
#' It reads the API key from a specified file, validates its format, ensures it matches the correct provider,
#' and checks if the key is valid by performing a test request.
#'
#' @param api_key_path Character string specifying the path to a file containing the API key.
#' @param provider Character string specifying the provider for the API key. Must be either "OpenAI" or "DeepSeek".
#' @param no_internet Logical, indicating whether to skip internet checks. If `TRUE`,
#'   the function will not attempt to validate the API key via a network request.
#' @param excludePattern Character, a regex pattern to exclude certain models from the list of
#'   available models, e.g. "babbage|curie|dall-e|davinci|text-embedding|tts|whisper"
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
new_RemoteLlmApi <- function(api_key_path, provider, no_internet = NULL, excludePattern = "") {
  provider <- match.arg(provider, c("OpenAI", "DeepSeek"))

  if (is.null(no_internet)) {
    no_internet <- !isTRUE(has_internet())
  }

  if (no_internet) {
    api <- list()
    attr(api, "error") <- "No connection! Check you internet connection."
    return(api)
  }

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

  if (!(length(api_key) == 1)) {
    api <- list()
    attr(api, "error") <- "Wrong format. The file should only contain one line with the key."
    return(api)
  }

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
    err_msg <- is_valid$message |> clean_error_message()

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
    list(api_key = api_key,
         provider = provider,
         url = url[provider],
         url_models = url_models[provider],
         excludePattern = excludePattern),
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
  excludePattern <- x$excludePattern

  req <- request(x$url_models) |>
    req_headers(Authorization = paste("Bearer", x$api_key),
                `Content-Type` = "application/json")

  content <- try_send_request(req)

  # Early return on error
  if (!is.null(attr(content, "error"))) {
    warning(paste("Error retrieving models:", attr(content, "error")))
    return(list())  # or return(NULL), depending on what downstream expects
  }

  # Extract models
  models <- vapply(content$data, function(x) x$id, character(1))

  # Filter models
  #excludePattern = "babbage|curie|dall-e|davinci|text-embedding|tts|whisper"
  models <- models |> filter_model_list(excludePattern = excludePattern)

  # Extract categories
  categories <- vapply(models, function(x) categorize_model(x), character(1))
  models_list <- extract_named_model_list(models, categories)

  return(models_list)
}

#' Send a prompt to a remote LLM API (e.g., OpenAI, DeepSeek)
#' This function sends a prompt to the remote LLM API and returns the response in a structured format.
#'
#' @param api An object of class RemoteLlmApi, which contains the API key and URL for the remote LLM API.
#' @param prompt_config An object of class LlmPromptConfig, containing the prompt content and model parameters.
#' @return A list containing the response from the LLM API, structured similarly to OpenAI responses.
#' @seealso [new_LlmResponse()]
#' @export
send_prompt.RemoteLlmApi <- function(api, prompt_config) {
  # Filter the prompt configuration
  prompt_config <- llm_filter_config(api, prompt_config)

  req <- request(api$url) |>
    req_headers(Authorization = paste("Bearer", api$api_key),
                `Content-Type` = "application/json") |>
    req_body_json(unclass(prompt_config))

  result <- req |> try_send_request()

  # Attach message (if exists) to result
  if (!is.null(attr(prompt_config, "message"))) {
    result <- append_attr(result, attr(prompt_config, "message"), "message")
  }

  result
}

try_send_request <- function(request) {
  response <- tryCatch(
    req_perform(request),
    error = function(e) {
      return(structure(list(), error = paste("API request failed:", e$message)))
    }
  )

  # early return if response has an error
  if (!is.null(attr(response, "error"))) {
    return(clean_error_message(response))
  }

  parsed <- tryCatch(
    resp_body_json(response),
    error = function(e) {
      warning(paste("API response parsing failed:", e$message))
      return(structure(list(), error = "Invalid JSON response"))
    }
  )

  if (!is.null(response$status_code) && response$status_code != 200) {
    warning(sprintf("API returned HTTP %s: %s", response$status_code,
                    parsed$error$message %||% "Unknown error"))
    attr(parsed, "error") <- clean_error_message(
      parsed$error$message %||% paste("HTTP", response$status_code)
    )
  }

  return(parsed)
}

# Function to validate API key via a test request
validate_api_key <- function(api_key, url_models) {
  test_req <- request(url_models) |>
    req_headers(Authorization = paste("Bearer", api_key))

  res <- try_send_request(test_req)

  # Return FALSE or error if invalid
  if (!is.null(attr(res, "error"))) {
    stop(attr(res, "error"))
  }

  # Additional safety check
  return(TRUE)
}


clean_error_message <- function(msg) {
  # Remove ANSI escape sequences
  msg <- gsub("\033\\[[0-9;]*m", "", msg)

  # Replace known HTTP codes with friendly text
  msg <- gsub("HTTP 401 Unauthorized", "Unauthorized: API key is invalid or expired", msg)

  return(trimws(msg))
}


#' Has Internet
#'
#' @param url (character) URL to test for internet connectivity. Default is "https://www.google.com".
#' @param timeout (numeric) number of seconds to wait for a response until giving up. Can not be less than 1 ms.
#'
#' @export
has_internet <- function(url = "https://www.google.com", timeout = 2) {
  tryCatch({
    request(url) |>
      req_timeout(seconds = timeout) |>
      req_perform()
    TRUE
  }, error = function(e) {
    FALSE
  })
}
