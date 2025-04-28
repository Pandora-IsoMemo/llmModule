#' Create an Ollama Model Object
#'
#' Constructs an S3 object representing a single Ollama model,
#' including its name and status (e.g., ready, pulled, error).
#'
#' @param model_name Character string, the model's name
#' @param status Character string, model status ("ready", "pulled", "error")
#' @param message Optional character string, error message if any
#'
#' @return An object of class OllamaModel
#' @export
new_OllamaModel <- function(model_name, status = "ready", message = NULL) {

  model_obj <- structure(
    list(
      model_name = model_name,
      status = status,
      message = message
    ),
    class = "OllamaModel"
  )

  return(model_obj)
}

#' Print method for OllamaModel
#'
#' @param x An OllamaModel object
#' @param ... Additional arguments
#' @export
print.OllamaModel <- function(x, ...) {
  cat("Ollama Model\n")
  cat("Model Name:", x$model_name, "\n")
  cat("Status:", x$status, "\n")
  if (!is.null(x$message)) {
    cat("Message:", x$message, "\n")
  }
}
