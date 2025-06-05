# Test Ollama Server Connection
#
# Checks if the local Ollama server is running and reachable.
#
# @return Logical TRUE if server is running, FALSE otherwise.
#
# @keywords internal
# @export
is_server_running <- function(url = Sys.getenv("OLLAMA_BASE_URL")) {
  tryCatch({
    res <- test_connection(url = url)
    return(isTRUE(res))
  }, error = function(e) {
    return(FALSE)
  })
}

# Clean and Match Model Name
#
# Tries to match a user-provided model name to a local available model,
# allowing flexibility like omitting ":latest" or using partial names.
#
# @param manager An OllamaModelManager object.
# @param input_name Character string, user-provided model name.
#
# @return Character string, matched model name if found, otherwise original input.
#
# @keywords internal
# @export
clean_model_name <- function(manager, input_name) {

  if (is.null(manager$local_models)) {
    manager <- update(manager)
  }

  models_local <- manager$local_models

  # Exact match
  if (input_name %in% models_local) {
    return(input_name)
  }

  # Try adding ":latest"
  input_with_latest <- paste0(input_name, ":latest")
  if (input_with_latest %in% models_local) {
    return(input_with_latest)
  }

  # Loose "starts with" match
  matched <- models_local[grepl(paste0("^", input_name), models_local)]
  if (length(matched) >= 1) {
    return(matched[1])
  }

  # No match found
  return(input_name)
}

# Check if a model is already available locally
#
# @param manager An OllamaModelManager object
# @param model_name Character string of the model name
# @return Logical TRUE if available, FALSE otherwise
# @export
is_model_available <- function(manager, model_name) {
  if (is.null(manager$local_models)) {
    manager <- update(manager)
  }

  return(model_name %in% manager$local_models)
}

# Pull a model if not available locally
#
# @param manager An OllamaModelManager object
# @param model_name Character string of the model name
# @return An OllamaModel object
# @export
pull_model_if_needed <- function(manager, model_name) {

  available <- is_model_available(manager, model_name)

  if (available) {
    model_obj <- structure(
      list(model_name = model_name, status = "ready"),
      class = "OllamaModel"
    )
    return(list(manager = manager, model = model_obj))
  }

  # Show message
  message(sprintf("Pulling in progress: '%s' This may take some time ...", model_name))

  # Try pulling the model
  pull_result <- tryCatch(
    pull(model_name, host = Sys.getenv("OLLAMA_BASE_URL")),
    error = function(e) e
  )

  if (inherits(pull_result, "error")) {
    model_obj <- new_OllamaModel(model_name, status = "error", message = pull_result$message)
    return(list(manager = manager, model = model_obj))
  }

  # After pulling, update local models
  manager <- update(manager)

  model_obj <- new_OllamaModel(model_name, status = "pulled")

  return(list(manager = manager, model = model_obj))
}
