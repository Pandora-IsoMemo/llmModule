#' Create and Manage LLM Prompt Settings
#'
#' The new_LlmPromptSettings() function constructs an S3 object that stores the parameters required for
#' making requests to Large Language Models (LLMs) such as OpenAI's GPT models and DeepSeek models.
#'
#' @param prompt_content character string containing the primary instruction or query for the model. This serves as the main input to the LLM.
#' @param model Character string specifying the model to use (e.g., `'gpt-4-turbo'` for OpenAI or `'deepseek-chat'` for DeepSeek). To retrieve a list of valid models for each LLM, use the \code{get_llm_models()} function.
#'
#' See the following documentation for valid models:
#' - \href{https://platform.openai.com/docs/models}{OpenAI model list}
#' - \href{https://api-docs.deepseek.com/api/list-models}{DeepSeek model list}
#'
#' @param prompt_role character (default: 'user') specifying the role of the message. Common values include 'system', 'assistant', and 'user'.
#' @param seed numeric (optional) for controlling reproducibility. If NULL, no seed is set.
#' @param max_tokens numeric (default: 100) defining the maximum number of tokens to be generated in the response.
#' @param temperature numeric (default: 1.0) controlling randomness in responses. Lower values (e.g., 0.2) make responses deterministic, while higher values (e.g., 1.5) increase creativity.
#' @param top_p numeric (default: 1) alternative to temperature, specifying nucleus sampling probability. A value of 0.1 considers only the top 10\% probability mass.
#' @param n numeric (default: 1) defining the number of responses to generate per request. If temperature is 0, n is automatically set to 1.
#' @param stop character or character vector (default: NULL) defining stop sequences for response termination. Up to 4 sequences can be specified.
#' @param presence_penalty numeric (default: 0) between -2.0 and +2.0, influencing model inclination to introduce new topics.
#' @param frequency_penalty numeric (default: 0) between -2.0 and +2.0, influencing model tendency to repeat words or phrases.
#' @param logprobs boolean (default: FALSE) specifying whether to return log probabilities for output tokens.
#'
#' @return An object of class LlmPromptSettings, containing all specified parameters in a structured format.
#'
#' @examples
#' \dontrun{
#' # Retrieve available models
#' api <- new_LlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
#' models <- get_llm_models(api)
#' }
#'
#' # Create a parameter object for OpenAI GPT-4 Turbo
#' params <- new_LlmPromptSettings(
#'   prompt_content = 'Explain entropy in simple terms.',
#'   model = 'gpt-4-turbo',
#'   temperature = 0.7,
#'   max_tokens = 150
#' )
#'
#' # Create a parameter object for DeepSeek
#' params <- new_LlmPromptSettings(
#'   prompt_content = 'What are three innovative AI research topics?',
#'   model = 'deepseek-chat',
#'   temperature = 0.9,
#'   n = 3
#' )
#'
#' # Print the parameter object
#' print(params)
#' @export
new_LlmPromptSettings <- function(prompt_content,
                                  model,
                                  prompt_role = 'user',
                                  seed = NULL,
                                  max_tokens = 100,
                                  temperature = 1.0,
                                  top_p = 1,
                                  n = 1,
                                  stop = NULL,
                                  presence_penalty = 0,
                                  frequency_penalty = 0,
                                  logprobs = FALSE) {
  # Create message structure
  messages <- data.frame(role = prompt_role, content = prompt_content, stringsAsFactors = FALSE)

  # Create prompt settings list
  prompt_settings <- list(
    messages = messages,
    model = model,
    seed = seed,
    max_tokens = max_tokens,
    temperature = temperature,
    top_p = top_p,
    n = n,
    stop = stop,
    presence_penalty = presence_penalty,
    frequency_penalty = frequency_penalty,
    logprobs = logprobs
  )

  # Validate model
  if (is.character(model) && model == "") {
    settings <- list()
    attr(settings, "error") <- "Model cannot be an empty string."
    return(settings)
  }

  # Validate temperature and n
  if (temperature == 0 & n > 1) {
    n <- 1
    n_msg <- "You are running the deterministic model, so `n` was set to 1 to avoid unnecessary token quota usage."
    prompt_settings <- append_attr(prompt_settings, n_msg, attr_name = "message")
    message(n_msg)
  }

  # Ensure seed is numeric or NULL
  if (is.numeric(seed)) {
    seed <- as.integer(seed)
    seed_msg <- sprintf("Seed set to '%s'.", seed)
    prompt_settings <- append_attr(prompt_settings, seed_msg, attr_name = "message")
    message(seed_msg)
  } else
    seed <- NULL

  # Construct S3 object
  structure(prompt_settings, class = "LlmPromptSettings")
}

#' Print method for better readability
#'
#' @param x An LlmPromptSettings object
#' @param ... Additional arguments
#'
#' @export
print.LlmPromptSettings <- function(x, ...) {
  cat("LLM Promp Settings\n")
  cat("Model:", x$model, "\n")
  if (!is.null(x$messages)) {
    if (!is.null(x$messages$role))
      cat("Prompt Role:", x$messages$role, "\n")
    if (!is.null(x$messages$content))
      cat("Prompt Content:", x$messages$content, "\n")
  }
  cat("Max Tokens:", x$max_tokens, "\n")
  cat("Temperature:", x$temperature, "\n")
  cat("Top-P:", x$top_p, "\n")
  cat("N:", x$n, "\n")
  if (!is.null(x$stop)) cat("Stop Sequences:", paste(x$stop, collapse = ", "), "\n")
  if (!is.null(x$seed)) cat("Seed:", x$seed, "\n")
}

# Append attribute to object
append_attr <- function(object, val, attr_name) {
  existing <- attr(object, attr_name)
  attr(object, attr_name) <- c(existing, val)
  object
}
