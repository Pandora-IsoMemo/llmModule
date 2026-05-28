#' Create a provider-routed LLM API object
#'
#' `new_BridgedLlmApi()` is a routing constructor that keeps legacy providers
#' (`OpenAI`, `DeepSeek`) on `RemoteLlmApi` and uses `EllmerLlmApi` as a bridge
#' for all other providers.
#'
#' @param provider Character provider name.
#' @param api_key_path Character path to API key file.
#' @param no_internet Logical, passed through to `new_RemoteLlmApi()` for legacy providers.
#' @param exclude_pattern Character regex for model exclusion.
#' @param model Character optional default model for bridged providers.
#'
#' @return An object of class `RemoteLlmApi` (for `OpenAI`/`DeepSeek`) or
#'   `EllmerLlmApi` + `LlmApi` (for all other providers).
#' @export
new_BridgedLlmApi <- function(
  provider,
  api_key_path,
  no_internet = NULL,
  exclude_pattern = "",
  model = NULL
) {
  if (missing(provider) || !is.character(provider) || nchar(trimws(provider)) == 0) {
    api <- list()
    attr(api, "error") <- "No valid provider supplied."
    return(api)
  }

  provider <- trimws(provider)

  if (provider %in% c("OpenAI", "DeepSeek")) {
    return(new_RemoteLlmApi(
      api_key_path = api_key_path,
      provider = provider,
      no_internet = no_internet,
      exclude_pattern = exclude_pattern
    ))
  }

  new_EllmerLlmApi(
    provider = provider,
    api_key_path = api_key_path,
    model = model,
    exclude_pattern = exclude_pattern
  )
}

#' Create an Ellmer bridge API object
#'
#' @param provider Character provider name.
#' @param api_key_path Character path to API key file.
#' @param model Character optional default model.
#' @param exclude_pattern Character regex for model exclusion.
#'
#' @return An object of class `EllmerLlmApi` and `LlmApi`, or a list with
#'   attribute `error` on failure.
#' @export
new_EllmerLlmApi <- function(
  provider,
  api_key_path,
  model = NULL,
  exclude_pattern = ""
) {
  if (missing(provider) || !is.character(provider) || nchar(trimws(provider)) == 0) {
    api <- list()
    attr(api, "error") <- "No valid provider supplied."
    return(api)
  }

  key_data <- read_bridge_api_key(api_key_path)
  if (!is.null(attr(key_data, "error"))) {
    return(key_data)
  }

  provider <- trimws(provider)
  key_msg <- validate_bridge_api_key(key_data$api_key, provider)
  if (!is.null(key_msg)) {
    api <- list()
    attr(api, "error") <- key_msg
    return(api)
  }

  structure(
    list(
      provider = provider,
      api_key = key_data$api_key,
      model = model,
      exclude_pattern = exclude_pattern,
      bridge = "ellmer"
    ),
    class = c("EllmerLlmApi", "LlmApi")
  )
}

read_bridge_api_key <- function(api_key_path) {
  if (missing(api_key_path) || !is.character(api_key_path) || nchar(trimws(api_key_path)) == 0) {
    api <- list()
    attr(api, "error") <- "No valid API key path."
    return(api)
  }

  if (!file.exists(api_key_path)) {
    api <- list()
    attr(api, "error") <- "API key file does not exist."
    return(api)
  }

  api_key <- trimws(readLines(api_key_path, warn = FALSE))
  if (length(api_key) != 1) {
    api <- list()
    attr(api, "error") <- "Wrong format. The file should only contain one line with the key."
    return(api)
  }

  list(api_key = api_key)
}

validate_bridge_api_key <- function(api_key, provider) {
  if (!is.character(api_key) || nchar(api_key) == 0) {
    return("API key is empty.")
  }

  if (nchar(api_key) < 20) {
    return("API key appears too short.")
  }

  provider_patterns <- list(
    Anthropic = "^sk-ant-",
    OpenRouter = "^sk-or-",
    Groq = "^gsk_",
    Mistral = "^mistral_"
  )

  pattern <- provider_patterns[[provider]]
  if (!is.null(pattern) && !grepl(pattern, api_key)) {
    return(sprintf("API key does not match the selected provider '%s'.", provider))
  }

  generic_pattern <- "^[A-Za-z0-9._:-]+$"
  if (!grepl(generic_pattern, api_key)) {
    return("API key format contains unsupported characters.")
  }

  NULL
}

#' Print method for EllmerLlmApi
#'
#' @param x An EllmerLlmApi object
#' @param ... Additional arguments
#' @export
print.EllmerLlmApi <- function(x, ...) {
  cat("Ellmer LLM Bridge\n")
  cat("Provider:", x$provider, "\n")
  cat("Bridge:", x$bridge, "\n")
  cat("API Key: [hidden]\n")
  if (!is.null(x$model)) {
    cat("Model:", x$model, "\n")
  }
}