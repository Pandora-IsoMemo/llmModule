#' Create and Structure LLM Response Object
#'
#' The new_LlmResponse() function sends a prompt to a Large Language Model (LLM) API and returns a structured response object.
#' It integrates the credentials from an LlmApi object and the prompt configuration from an LlmPromptSettings object,
#' handles request errors gracefully, and returns the model-generated content along with associated metadata.
#'
#' @param api An object of class LlmApi, created using new_LlmApi(), containing the API key, endpoint, and provider name.
#' @param prompt_settings An object of class LlmPromptSettings, containing prompt content, model, and tuning parameters
#'   (e.g., temperature, max tokens).
#'
#' @return An object of class LlmResponse, which includes the following components:
#'
#' - content: The raw API response returned from the model.
#' - provider: The name of the API provider (e.g., "OpenAI", "DeepSeek").
#' - prompt_settings: The unclassed list representation of the original prompt settings.
#' - generated_text: The primary response text content from the model.
#'
#' If an error occurs during validation or request sending, an empty list is returned with an error attribute containing the error message.
#'
#' @examples
#' api <- new_LlmApi(api_key_path = "path/to/key.txt", provider = "OpenAI")
#' prompt <- new_LlmPromptSettings(
#'   prompt_content = "Explain entropy in simple terms.",
#'   model = "gpt-3.5-turbo",
#'   temperature = 0.7
#' )
#' response <- new_LlmResponse(api, prompt)
#'
#' if (!is.null(attr(response, "error"))) {
#'   cat("Error:", attr(response, "error"), "\n")
#' } else {
#'   cat("Model response:", response$generated_text, "\n")
#' }
#'
#' @seealso [new_LlmApi()], [new_LlmPromptSettings()]]
#' @export
new_LlmResponse <- function(api, prompt_settings) {
  if (!inherits(api, "LlmApi")) {
    response <- list()
    attr(response, "error") <- "API not valid, must be an LlmApi object."
    return(response)
  }
  if (!inherits(prompt_settings, "LlmPromptSettings")) {
    response <- list()
    attr(response, "error") <- "Prompt settings not valid, must be an LlmPromptSettings object."
    return(response)
  }

  # send request
  content <- tryCatch(
    send_prompt(api, prompt_settings),
    error = function(e) e
  )

  if (inherits(content, "error")) {
    response <- list()
    attr(response, "error") <- content$message
    return(response)
  }

  structure(
    list(
      content = content,
      provider = api$provider,
      prompt_settings = unclass(prompt_settings),
      generated_text = content$choices[[1]]$message$content
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
  cat("LLM Response Object\n")
  cat("Provider:", x$provider, "\n")
  cat("Model:", x$prompt_settings$model, "\n")
  cat("Temperature:", x$prompt_settings$temperature, "\n")
  cat("Generated Text:\n")
  cat(x$content$choices[[1]]$message$content, "\n")
}

send_prompt <- function(api, prompt_settings) {
  req <- request(api$url) |>
    req_headers(Authorization = paste("Bearer", api$api_key),
                `Content-Type` = "application/json") |>
    req_body_json(unclass(prompt_settings))

  req |>
    req_perform() |>
    resp_body_json()
}
