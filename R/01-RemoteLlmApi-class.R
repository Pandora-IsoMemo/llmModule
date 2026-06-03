#' Create and Validate Remote LLM API Credentials
#'
#' The new_RemoteLlmApi() function constructs an S3 object that stores API credentials for interacting
#' with Large Language Models (LLMs) such as OpenAI's GPT models and DeepSeek models.
#' It reads the API key from a specified file and validates local key structure.
#' Network availability and credential checks are performed later when models are listed
#' or prompts are sent.
#'
#' @param provider Character string specifying the provider for the API key. Must be either "OpenAI" or "DeepSeek".
#' @param api_key Character string containing the API key.
#' @param api_key_path Deprecated path to a file containing the API key.
#' @param no_internet Logical override for runtime request checks. If `TRUE`,
#'   internet-dependent operations return a connection error without making requests.
#' @param exclude_pattern Character, a regex pattern to exclude certain models from the list of
#'   available models, e.g. "babbage|curie|dall-e|davinci|text-embedding|tts|whisper"
#'
#' @return An object of class RemoteLlmApi, containing the API key, URL, and provider name
#'  (either "OpenAI" or "DeepSeek"), or a list with an "error" attribute if construction fails.
#'
#' @details
#' This function includes multiple validation steps:
#' - Reads the API key from the specified file.
#' - Ensures the API key file has a valid one-line format and sufficient length.
#' - Stores provider endpoints and optional runtime connectivity override settings.
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
new_RemoteLlmApi <- function(
  provider,
  api_key = NULL,
  api_key_path = NULL,
  no_internet = NULL,
  exclude_pattern = ""
) {
  provider <- match.arg(provider, c("OpenAI", "DeepSeek"))

  if (is_valid_character(api_key)) {
    api_key <- trimws(api_key)
  } else if (is_valid_character(api_key_path)) {
    lifecycle::deprecate_warn(
      when = "26.05.2",
      what = "llmModule::new_RemoteLlmApi(api_key_path)",
      with = "llmModule::new_RemoteLlmApi(api_key)",
      details = "Passing auth via file path is deprecated; pass the key string directly instead."
    )

    if (!file.exists(api_key_path)) {
      api <- list()
      attr(api, "error") <- "API key file does not exist."
      return(api)
    }

    api_key <- trimws(readLines(api_key_path, warn = FALSE))
  } else {
    api <- list()
    attr(api, "error") <- "No valid API key supplied."
    return(api)
  }

  if (length(api_key) != 1) {
    api <- list()
    attr(api, "error") <- "Wrong format. The API key should only contain one value."
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

  api_obj <- structure(
    list(api_key = api_key,
         provider = provider,
         url = url[provider],
         url_models = url_models[provider],
         no_internet = no_internet,
         exclude_pattern = exclude_pattern),
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
  exclude_pattern <- x$exclude_pattern

  connectivity_error <- check_remote_connectivity(x$no_internet)
  if (!is.null(connectivity_error)) {
    warning(paste("Error retrieving models:", connectivity_error), call. = FALSE)
    return(list())
  }

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
  models <- models |> filter_model_list(exclude_pattern = exclude_pattern)

  # Extract categories
  categories <- vapply(models, function(x) categorize_model(x), character(1))
  models_list <- extract_named_model_list(models, categories)

  return(models_list)
}

#' Retrieve Available LLM Models plus metadata
#'
#' @param x An object of class RemoteLlmApi
#' @param ... Additional arguments
#' @return A `LlmModelsInfo` object with `models` and selection metadata.
#' @export
get_llm_models_info.RemoteLlmApi <- function(x, ...) {
  models <- get_llm_models.RemoteLlmApi(x, ...)
  listing_status <- if (length(models) > 0) "ok" else "empty"

  new_LlmModelsInfo(
    models = models,
    can_fallback_to_provider_default = FALSE,
    requires_explicit_model = TRUE,
    listing_status = listing_status,
    provider = x$provider
  )
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

  connectivity_error <- check_remote_connectivity(api$no_internet)
  if (!is.null(connectivity_error)) {
    result <- list()
    attr(result, "error") <- connectivity_error

    if (!is.null(attr(prompt_config, "message"))) {
      result <- append_attr(result, attr(prompt_config, "message"), "message")
    }

    return(result)
  }

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
      msg <- e$message |> clean_error_message(
        replace_text = c("HTTP 401 Unauthorized" = "Unauthorized: API key is invalid or expired")
      )
      return(structure(list(), error = paste("API request failed:", msg)))
    }
  )

  # early return if response has an error
  if (!is.null(attr(response, "error"))) {
    return(response)
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
    attr(parsed, "error") <- parsed$error$message %||% paste("HTTP", response$status_code) |>
      clean_error_message(
        replace_text = c("HTTP 401 Unauthorized" = "Unauthorized: API key is invalid or expired")
      )
  }

  return(parsed)
}

check_remote_connectivity <- function(no_internet = NULL) {
  if (is.null(no_internet)) {
    no_internet <- !isTRUE(has_internet())
  }

  if (isTRUE(no_internet)) {
    return("No connection! Check your internet connection.")
  }

  NULL
}

clean_error_message <- function(msg, replace_text = c()) {
  # Remove ANSI escape sequences
  msg <- gsub("\033\\[[0-9;]*m", "", msg)

  # Replace specified patterns
  if (length(replace_text) > 0) {
    for (pattern in names(replace_text)) {
      msg <- gsub(pattern, replace_text[[pattern]], msg)
    }
  }

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
