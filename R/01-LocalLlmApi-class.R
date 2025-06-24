#' Create and Validate Local LLM API Credentials
#'
#' @param manager An OllamaModelManager object
#' @param new_model Character, model name input from user (can be partial) of the model to pull
#' @param base_url Local Ollama base URL
#' @param exclude_pattern  Character, a regex pattern to exclude certain models from the list of
#'   available models, e.g. "babbage|curie|dall-e|davinci|text-embedding|tts|whisper"
#'
#' @return An object of class LocalLlmApi, or a list with an "error" attribute if construction fails.
#' @export
new_LocalLlmApi <- function(
    manager,
    new_model = "",
    base_url = Sys.getenv("OLLAMA_BASE_URL", unset = "http://localhost:11434"),
    exclude_pattern = ""
) {
  if (!requireNamespace("ollamar", quietly = TRUE)) {
    api <- list()
    attr(api, "error") <- "The 'ollamar' package is required for this function, but is not installed."
    return(api)
  }

  if (!is_ollama_running(url = base_url)) {
    api <- list()
    attr(api, "error") <- sprintf("Ollama server does not appear to be running at the specified base URL: '%s%'.", base_url)
    return(api)
  }

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
      provider = "Ollama",
      manager = manager,
      exclude_pattern = exclude_pattern
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
  exclude_pattern <- x$exclude_pattern

  # Extract models
  models <- vapply(local_models, function(x) x, character(1))

  # Filter models
  models <- models |> filter_model_list(exclude_pattern = exclude_pattern)

  # Extract categories
  categories <- vapply(models, function(x) categorize_model(x), character(1))

  models_list <- extract_named_model_list(models, categories)

  return(models_list)
}

#' Send a prompt to a local llm API (e.g., Ollama)
#'
#' This function sends a prompt to the local LLM API (Ollama) and returns the response in a structured format.
#' @param api An object of class LocalLlmApi, which contains the URL and model name for the local LLM API.
#' @param prompt_config An object of class LlmPromptConfig, containing the prompt content and model parameters.
#' @return A list containing the response from the Ollama API, structured similarly to OpenAI responses.
#' @seealso [new_LlmResponse()]
#' @export
send_prompt.LocalLlmApi <- function(api, prompt_config) {
  # Filter the prompt configuration
  prompt_config <- llm_filter_config(api, prompt_config)
  body <- list(
    model = prompt_config$model,
    prompt = prompt_config$messages$content,
    stream = FALSE
  )

  # Add optional parameters if available
  if (!is.null(prompt_config$temperature)) {
    body$temperature <- prompt_config$temperature
  }
  if (!is.null(prompt_config$top_p)) {
    body$top_p <- prompt_config$top_p
  }
  if (!is.null(prompt_config$stop)) {
    body$stop <- prompt_config$stop
  }
  if (!is.null(prompt_config$seed)) {
    body$seed <- prompt_config$seed
  }
  if (!is.null(prompt_config$max_tokens)) {
    body$num_predict <- prompt_config$max_tokens
  }

  resp <- request(paste0(api$url, "/api/generate")) |>
    req_body_json(body) |>
    try_send_request()

  # return early if there was an error
  if (!is.null(attr(resp, "error"))) {
    return(resp)
  }

  result <- list(
    choices = list(
      list(message = list(
        role = "assistant",
        content = resp$response
      ))
    )
  )

  # Attach message (if exists) to result
  if (!is.null(attr(prompt_config, "message"))) {
    result <- append_attr(result, attr(prompt_config, "message"), "message")
  }

  result
}
