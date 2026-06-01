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
  if (!is_valid_character(provider)) {
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
  if (!is_valid_character(provider)) {
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
  if (!is_valid_character(api_key_path)) {
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

#' Retrieve Available LLM Models via Ellmer bridge
#'
#' @param x An EllmerLlmApi object
#' @param ... Additional arguments
#' @return Character vector or named list of available models
#' @export
get_llm_models.EllmerLlmApi <- function(x, ...) {
  model_data <- tryCatch(
    bridge_models_list(x),
    error = function(e) e
  )

  if (inherits(model_data, "error")) {
    # Do not fail hard when provider listing is unavailable.
    fallback_models <- x$model
    if (is.null(fallback_models) || identical(fallback_models, "")) {
      warning(sprintf("Error retrieving models for provider '%s': %s", x$provider, model_data$message), call. = FALSE)
      return(list())
    }
    return(fallback_models)
  }

  models <- extract_bridge_model_ids(model_data)
  models <- filter_model_list(models, x$exclude_pattern)

  if (length(models) == 0) {
    fallback_models <- x$model
    if (!is.null(fallback_models) && !identical(fallback_models, "")) {
      return(fallback_models)
    }
    return(list())
  }

  categories <- vapply(models, function(id) categorize_model(id), character(1))
  extract_named_model_list(models, categories)
}

#' Send a prompt through the Ellmer bridge
#'
#' @param api An EllmerLlmApi object
#' @param prompt_config An LlmPromptConfig object
#' @return Normalized response with OpenAI-like `choices[[1]]$message$content`
#' @export
send_prompt.EllmerLlmApi <- function(api, prompt_config) {
  prompt_config <- llm_filter_config(api, prompt_config)

  model <- prompt_config$model %||% api$model
  if (is.null(model) || identical(model, "")) {
    response <- list()
    attr(response, "error") <- "No model specified for Ellmer bridge request."
    return(response)
  }

  prompt_parts <- bridge_prompt_parts(prompt_config)

  chat_obj <- tryCatch(
    bridge_chat_create(
      api = api,
      model = model,
      system_prompt = prompt_parts$system_prompt,
      params = bridge_params_from_config(prompt_config)
    ),
    error = function(e) e
  )

  if (inherits(chat_obj, "error")) {
    response <- list()
    attr(response, "error") <- paste("Bridge initialization failed:", clean_error_message(chat_obj$message))
    return(response)
  }

  turn <- tryCatch(
    bridge_chat_send(chat_obj, prompt_parts$user_prompt),
    error = function(e) e
  )

  if (inherits(turn, "error")) {
    response <- list()
    attr(response, "error") <- paste("API request failed:", clean_error_message(turn$message))
    return(response)
  }

  text <- tryCatch(
    bridge_extract_text(turn),
    error = function(e) e
  )

  if (inherits(text, "error") || !is.character(text) || length(text) == 0) {
    response <- list()
    attr(response, "error") <- "Bridge response parsing failed: no assistant text available."
    return(response)
  }

  normalized <- list(
    choices = list(
      list(
        message = list(
          role = "assistant",
          content = paste(text, collapse = "\n")
        )
      )
    )
  )

  if (!is.null(attr(prompt_config, "message"))) {
    normalized <- append_attr(normalized, attr(prompt_config, "message"), "message")
  }

  normalized
}

bridge_provider_key <- function(provider) {
  tolower(gsub("[^A-Za-z0-9]+", "_", trimws(provider)))
}

bridge_provider_function <- function(prefix, provider) {
  fn_name <- paste0(prefix, bridge_provider_key(provider))
  get0(fn_name, envir = asNamespace("ellmer"), mode = "function", inherits = FALSE)
}

bridge_models_list <- function(api) {
  models_fun <- bridge_provider_function("models_", api$provider)
  if (is.null(models_fun)) {
    stop(sprintf("No model-listing bridge available for provider '%s'.", api$provider))
  }

  do.call(models_fun, list(api_key = api$api_key))
}

extract_bridge_model_ids <- function(model_data) {
  if (is.null(model_data)) {
    return(character(0))
  }

  if (is.character(model_data)) {
    return(unname(model_data))
  }

  if (is.data.frame(model_data)) {
    if ("id" %in% names(model_data)) {
      return(as.character(model_data$id))
    }

    chr_cols <- names(model_data)[vapply(model_data, is.character, logical(1))]
    if (length(chr_cols) > 0) {
      return(as.character(model_data[[chr_cols[[1]]]]))
    }
  }

  if (is.list(model_data)) {
    ids <- vapply(model_data, function(entry) {
      if (is.character(entry) && length(entry) == 1) {
        return(entry)
      }
      if (is.list(entry) && !is.null(entry$id)) {
        return(as.character(entry$id))
      }
      NA_character_
    }, character(1))

    ids <- ids[!is.na(ids)]
    if (length(ids) > 0) {
      return(ids)
    }
  }

  character(0)
}

bridge_params_from_config <- function(prompt_config) {
  param_names <- c("temperature", "max_tokens", "top_p", "n", "stop", "seed")
  params <- list()

  for (name in param_names) {
    value <- prompt_config[[name]]
    if (!is.null(value) && !(is.character(value) && identical(value, "")) && !(length(value) == 1 && is.na(value))) {
      params[[name]] <- value
    }
  }

  params
}

bridge_prompt_parts <- function(prompt_config) {
  messages <- prompt_config$messages

  if (is.null(messages) || nrow(messages) == 0) {
    return(list(system_prompt = NULL, user_prompt = ""))
  }

  roles <- as.character(messages$role)
  contents <- as.character(messages$content)

  system_prompt <- contents[roles == "system"]
  if (length(system_prompt) == 0) {
    system_prompt <- NULL
  } else {
    system_prompt <- paste(system_prompt, collapse = "\n\n")
  }

  user_content <- contents[roles != "system"]
  if (length(user_content) == 0) {
    user_content <- contents
  }

  list(
    system_prompt = system_prompt,
    user_prompt = paste(user_content, collapse = "\n\n")
  )
}

bridge_chat_create <- function(api, model, system_prompt, params) {
  chat_fun <- bridge_provider_function("chat_", api$provider)
  if (is.null(chat_fun)) {
    stop(sprintf("No chat bridge available for provider '%s'.", api$provider))
  }

  suppressWarnings(
    do.call(chat_fun, list(
      model = model,
      system_prompt = system_prompt,
      params = params,
      api_key = api$api_key,
      echo = "none"
    ))
  )
}

bridge_chat_send <- function(chat_obj, prompt) {
  chat_obj$chat(prompt)
}

bridge_extract_text <- function(turn) {
  text <- ellmer::contents_text(turn)
  if (is.null(text)) {
    return(character(0))
  }
  as.character(text)
}