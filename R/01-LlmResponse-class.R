new_LlmResponse <- function(content, params) {
  structure(
    list(
      content = content,
      params = params
    ),
    class = "LlmResponse"
  )
}

#' Print method for user-friendly display
#'
#' @param x An LlmResponse object
#' @param ... Additional arguments
#'
#' @export
print.LlmResponse <- function(x, ...) {
  provider <- get_provider_from_model(x$params$model)
  cat("LLM Response Object\n")
  cat("Provider:", provider, "\n")
  cat("Model:", x$params$model, "\n")
  cat("Temperature:", x$params$temperature, "\n")
  cat("Generated Text:\n")
  cat(x$content$choices[[1]]$message$content, "\n")
}

get_provider_from_model <- function(model) {
  if (grepl("^gpt-", model, ignore.case = TRUE)) {
    return("OpenAI")
  } else if (grepl("^deepseek-", model, ignore.case = TRUE)) {
    return("DeepSeek")
  } else {
    return("Unknown Provider")
  }
}
