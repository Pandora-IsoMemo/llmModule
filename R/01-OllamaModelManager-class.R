#' Ollama Model Manager
#'
#' Manages the listing, checking, and pulling of Ollama models.
#'
#' @return An object of class OllamaModelManager
#' @export
new_OllamaModelManager <- function() {

  manager <- structure(
    list(
      local_models = NULL  # will cache pulled models (updated on demand)
    ),
    class = "OllamaModelManager"
  )

  return(manager)
}

#' Print method for OllamaModelManager
#'
#' @param x An OllamaModelManager object
#' @param ... Additional arguments
#' @export
print.OllamaModelManager <- function(x, ...) {
  cat("Ollama Model Manager\n")
  if (!is.null(x$local_models)) {
    cat("Local Models:\n")
    cat(paste0("- ", x$local_models), sep = "\n")
  } else {
    cat("No local models cached yet. Call update(x).\n")
  }
}

#' Update the list of locally available models
#'
#' @param x An OllamaModelManager object
#' @param ... Not used, for compatibility
#' @return Updated OllamaModelManager object
#' @export
update.OllamaModelManager <- function(x, ...) {
  models <- tryCatch(
    list_models(host = Sys.getenv("OLLAMA_BASE_URL")),
    error = function(e) {
      warning("Could not fetch local models. Is the Ollama server running?")
      return(data.frame())
    }
  )

  x$local_models <- models$name

  return(x)
}
