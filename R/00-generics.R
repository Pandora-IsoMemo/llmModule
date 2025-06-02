#' Generic extractor for LlmResponse outputs
#'
#' @param x An LlmResponse object
#' @param ... Additional arguments (not used)
#'
#' @export
as_table <- function(x, ...) {
  UseMethod("as_table")
}

#' Generic extractor for LlmApi outputs
#'
#' @param x An LlmApi object
#' @param ... Additional arguments
#'
#' @export
get_llm_models <- function(x, ...) {
  UseMethod("get_llm_models", x)
}

#' Generic LLM prompt sender
#' This function is a generic method for sending prompts to a remote or local LLM API.
#' It dispatches to the appropriate method based on the class of the `api` argument.
#' @param api An object of class RemoteLlmApi or LocalLlmApi, which contains the API key and URL for the remote LLM API.
#' @param prompt_config An object of class LlmPromptConfig, containing the prompt content and model parameters.
#' @export
send_prompt <- function(api, prompt_config) {
  UseMethod("send_prompt", api)
}

#' Generic update function
#'
#' Dispatches update methods for different object classes.
#'
#' @param x Object to update
#' @param ... Further arguments
#' @export
update <- function(x, ...) {
  UseMethod("update")
}
