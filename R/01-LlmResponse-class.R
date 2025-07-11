#' Create and Structure LLM Response Object
#'
#' The new_LlmResponse() function sends a prompt to a Large Language Model (LLM) API and returns a structured response object.
#' It integrates the credentials from an LlmApi object and the prompt configuration from an LlmPromptConfig object,
#' handles request errors gracefully, and returns the model-generated content along with associated metadata.
#'
#' @param api An object of class RemoteLlmApi or LocalLlmApi.
#' @param prompt_config An object of class LlmPromptConfig, containing prompt content, model, and tuning parameters
#'   (e.g., temperature, max tokens).
#'
#' @return An object of class LlmResponse, which includes the following components:
#'
#' - content: The raw API response returned from the model.
#' - provider: The name of the API provider (e.g., "OpenAI", "DeepSeek").
#' - prompt_config: The unclassed list representation of the original prompt settings.
#' - generated_text: The primary response text content from the model.
#'
#' If an error occurs during validation or request sending, an empty list is returned with an error attribute containing the error message.
#'
#' @examples
#' api <- new_RemoteLlmApi(api_key_path = "path/to/key.txt", provider = "OpenAI")
#' prompt <- new_LlmPromptConfig(
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
#' @seealso [new_RemoteLlmApi()], [new_LlmPromptConfig()]]
#' @export
new_LlmResponse <- function(api, prompt_config) {
  if (!inherits(api, "LlmApi")) {
    response <- list()
    attr(response, "error") <- "LLM API not valid, must be an RemoteLlmApi or LocalLlmApi object."
    return(response)
  }
  if (!inherits(prompt_config, "LlmPromptConfig")) {
    response <- list()
    attr(response, "error") <- "Prompt settings not valid, must be an LlmPromptConfig object."
    return(response)
  }

  # send request
  content <- tryCatch(
    send_prompt(api, prompt_config),
    error = function(e) e
  )

  if (!is.null(attr(content, "error"))) {
    return(content)
  }

  response <- structure(
    list(
      content = content,
      provider = api$provider,
      prompt_config = unclass(prompt_config),
      generated_text = content$choices[[1]]$message$content
    ),
    class = "LlmResponse"
  )

  # propagate message attr from send_prompt
  if (!is.null(attr(content, "message"))) {
    attr(response, "message") <- attr(content, "message")
  }

  return(response)
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
  cat("Model:", x$prompt_config$model, "\n")
  cat("Temperature:", x$prompt_config$temperature, "\n")
  cat("Generated Text:\n")
  cat(x$content$choices[[1]]$message$content, "\n")
}

#' Extract and format LLM response as a table
#'
#' @param x An LlmResponse object
#' @param output_type A character string indicating the type of output to format.
#'  Possible values are "text", "meta", "logprobs", or "complete".
#' @param ... Additional arguments (not used)
#' @return A formatted character string
#' @export
as_table.LlmResponse <- function(x, output_type = c("text", "meta", "logprobs", "complete"), ...) {
  output_type <- match.arg(output_type)

  switch(
    output_type,
    text = list(core_output = get_core_output(x)),
    meta = list(meta_output = get_meta_output(x)),
    logprobs = list(logprobs_output = get_logprobs_output(x)),
    complete = list(core_output = get_core_output(x),
                    meta_output = get_meta_output(x),
                    logprobs_output = get_logprobs_output(x))
  )
}

get_core_output <- function(x) {
  prompt_config <- x$prompt_config
  request_content <- x$content
  n <- length(request_content$choices)

  core_output = data.table::data.table(
    'n' = 1:n,
    'prompt_role' = rep(prompt_config$prompt_role, n),
    'prompt_content' = rep(prompt_config$prompt_content, n),
    'role' = rep("", n),
    'content' = rep("", n)
  )

  for (i in 1:n) {
    core_output$role[i] = request_content$choices[[i]]$message$role
    core_output$content[i] = request_content$choices[[i]]$message$content
  }

  return(core_output)
}

get_meta_output <- function(x) {
  content <- x$content
  ps <- x$prompt_config

  dt <- data.table::data.table(
    'param_prompt_content' = ps$prompt_content,
    'param_model' = ps$model,
    'param_temperature' = ps$temperature
  )

  for (entry in c("prompt_role", "seed_info", "max_tokens", "top_p", "n", "stop", "logprobs", "presence_penalty", "frequency_penalty")) {
    if (!is.null(ps[[entry]])) {
      dt[[sprintf("param_%s", entry)]] <- ps[[entry]]
    }
  }

  if (!is.null(content$id)) {
    dt$request_id <- content$id
  }

  for (entry in c("system_fingerprint", "object")) {
    if (!is.null(content[[entry]])) {
      dt[[entry]] <- content[[entry]]
    }
  }

  if (!is.null(content$usage)) {
    dt$tok_usage_prompt <- content$usage$prompt_tokens
    dt$tok_usage_completion <- content$usage$completion_tokens
    dt$tok_usage_total <- content$usage$total_tokens
  }

  dt
}

get_logprobs_output <- function(x) {
  # Check if logprobs were requested before text generation
  if (!x$prompt_config$logprobs) {
    return("'no logprobs requested'")
  }

  # Extract logprobs from the response
  request_content <- x$content
  n <- length(request_content$choices)

  get_single_logprobs <- function(i) {
    data_logprobs = request_content$choices[[i]]$logprobs[[1]]

    logprobs_output = data.table::data.table(
      'n' = i,
      'token' = rep("", length(data_logprobs)),
      'logprob' = rep(0, length(data_logprobs))
    )

    for (j in 1:length(data_logprobs)) {
      logprobs_output$token[j] = data_logprobs[[j]]$token
      logprobs_output$logprob[j] = data_logprobs[[j]]$logprob
    }

    logprobs_output
  }

  ## get logprobs
  if (n == 1) {
      logprobs_output <- get_single_logprobs(i = 1)
  } else {
    logprobs_output_list = list()

    for (i in 1:n) {
      logprobs_output_list[[i]] = get_single_logprobs(i)
    }

    logprobs_output = data.table::rbindlist(logprobs_output_list)
  }

  logprobs_output
}


