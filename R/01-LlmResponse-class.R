#' Create and Structure LLM Response Object
#'
#' The new_LlmResponse() function sends a prompt to a Large Language Model (LLM) API and returns a structured response object.
#' It integrates the credentials from an LlmApi object and the prompt configuration from an LlmPromptSettings object,
#' handles request errors gracefully, and returns the model-generated content along with associated metadata.
#'
#' @param api An object of class RemoteLlmApi or LocalLlmApi.
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
#' api <- new_RemoteLlmApi(api_key_path = "path/to/key.txt", provider = "OpenAI")
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
#' @seealso [new_RemoteLlmApi()], [new_LlmPromptSettings()]]
#' @export
new_LlmResponse <- function(api, prompt_settings) {
  if (!inherits(api, "LlmApi")) {
    response <- list()
    attr(response, "error") <- "LLM API not valid, must be an RemoteLlmApi or LocalLlmApi object."
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

#' Generic LLM prompt sender
#' This function is a generic method for sending prompts to a remote or local LLM API.
#' It dispatches to the appropriate method based on the class of the `api` argument.
#' @param api An object of class RemoteLlmApi or LocalLlmApi, which contains the API key and URL for the remote LLM API.
#' @param prompt_settings An object of class LlmPromptSettings, containing the prompt content and model parameters.
#' @export
send_prompt <- function(api, prompt_settings) {
  UseMethod("send_prompt", api)
}

#' Send a prompt to a remote LLM API (e.g., OpenAI, DeepSeek)
#' This function sends a prompt to the remote LLM API and returns the response in a structured format.
#'
#' @param api An object of class RemoteLlmApi, which contains the API key and URL for the remote LLM API.
#' @param prompt_settings An object of class LlmPromptSettings, containing the prompt content and model parameters.
#' @return A list containing the response from the LLM API, structured similarly to OpenAI responses.
#' @seealso [new_LlmResponse()]
#' @export
send_prompt.RemoteLlmApi <- function(api, prompt_settings) {
  req <- request(api$url) |>
    req_headers(Authorization = paste("Bearer", api$api_key),
                `Content-Type` = "application/json") |>
    req_body_json(unclass(prompt_settings))

  req |>
    req_perform() |>
    resp_body_json()
}

#' Send a prompt to a local llm API (e.g., Ollama)
#'
#' This function sends a prompt to the local LLM API (Ollama) and returns the response in a structured format.
#' @param api An object of class LocalLlmApi, which contains the URL and model name for the local LLM API.
#' @param prompt_settings An object of class LlmPromptSettings, containing the prompt content and model parameters.
#' @return A list containing the response from the Ollama API, structured similarly to OpenAI responses.
#' @seealso [new_LlmResponse()]
#' @export
send_prompt.LocalLlmApi <- function(api, prompt_settings) {
  body <- list(
    model = api$model_name,
    prompt = prompt_settings$prompt,
    stream = FALSE
  )

  req <- httr2::request(paste0(api$url, "/api/generate")) |>
    httr2::req_body_json(body) |>
    httr2::req_perform()

  resp <- httr2::resp_body_json(req)

  list(
    choices = list(
      list(message = list(
        role = "assistant",
        content = resp$response
      ))
    )
  )
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

#' Generic extractor for LlmResponse outputs
#'
#' @param x An LlmResponse object
#' @param ... Additional arguments (not used)
#'
#' @export
as_table <- function(x, ...) {
  UseMethod("as_table")
}

get_core_output <- function(x) {
  prompt_settings <- x$prompt_settings
  request_content <- x$content
  n <- length(request_content$choices)

  core_output = data.table::data.table(
    'n' = 1:n,
    'prompt_role' = rep(prompt_settings$prompt_role, n),
    'prompt_content' = rep(prompt_settings$prompt_content, n),
    'gpt_role' = rep("", n),
    'gpt_content' = rep("", n)
  )

  for (i in 1:n) {
    core_output$gpt_role[i] = request_content$choices[[i]]$message$role
    core_output$gpt_content[i] = request_content$choices[[i]]$message$content
  }

  return(core_output)
}

get_meta_output <- function(x) {
  content <- x$content
  ps <- x$prompt_settings

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
  if (!x$prompt_settings$logprobs) {
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


