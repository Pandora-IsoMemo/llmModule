testthat::test_that("send_prompt.EllmerLlmApi normalizes bridge output", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  prompt <- llmModule::new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Bridge says hello",
    .package = "llmModule"
  )

  testthat::expect_warning(
    result <- llmModule::send_prompt(api, prompt),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_equal(result$choices[[1]]$message$role, "assistant")
  testthat::expect_equal(result$choices[[1]]$message$content, "Bridge says hello")
})

testthat::test_that("new_LlmResponse works with normalized Ellmer bridge response", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  prompt <- llmModule::new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Normalized content",
    .package = "llmModule"
  )

  testthat::expect_warning(
    response <- llmModule::new_LlmResponse(api, prompt),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_s3_class(response, "LlmResponse")
  testthat::expect_equal(response$generated_text, "Normalized content")
})

testthat::test_that("send_prompt.EllmerLlmApi returns structured error when model missing", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Gemini", api_key = "token.alpha-1234:provider_key_567890")
  prompt <- llmModule::new_LlmPromptConfig(prompt_content = "Hello bridge", model = "placeholder")
  prompt$model <- NULL

  testthat::expect_warning(
    result <- llmModule::send_prompt(api, prompt),
    "ignored for provider 'Gemini'"
  )
  testthat::expect_equal(attr(result, "error"), "No model specified for Ellmer bridge request.")
})

testthat::test_that("get_llm_models.EllmerLlmApi categorizes extracted ids", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")

  testthat::local_mocked_bindings(
    bridge_models_list = function(api) list(
      list(id = "gpt-4.1"),
      list(id = "claude-3.5-sonnet")
    ),
    .package = "llmModule"
  )

  models <- llmModule::get_llm_models(api)

  testthat::expect_true(is.list(models) || is.character(models))
  flattened <- unlist(models, use.names = FALSE)
  testthat::expect_true("gpt-4.1" %in% flattened)
  testthat::expect_true("claude-3.5-sonnet" %in% flattened)
})

testthat::test_that("get_llm_models.EllmerLlmApi falls back to api$model when listing fails", {
  api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key = "sk-ant-validkey123456789012345",
    model = "claude-3-haiku"
  )

  testthat::local_mocked_bindings(
    bridge_models_list = function(api) stop("simulated model endpoint failure"),
    .package = "llmModule"
  )

  models <- llmModule::get_llm_models(api)
  testthat::expect_equal(models, "claude-3-haiku")
})

testthat::test_that("bridge_chat_send returns last turn when available", {
  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) "stream output"
  fake_chat_obj$last_turn <- function() "last turn text"

  result <- llmModule:::bridge_chat_send(fake_chat_obj, "hello")

  testthat::expect_equal(result, "last turn text")
})

testthat::test_that("bridge_extract_text accepts plain character output", {
  result <- llmModule:::bridge_extract_text("OK")

  testthat::expect_equal(result, "OK")
})

testthat::test_that("bridge_params_from_config maps prompt fields to ellmer params names", {
  prompt <- llmModule::new_LlmPromptConfig(
    prompt_content = "Hello",
    model = "claude-3-haiku",
    temperature = 0.7,
    top_p = 0.9,
    max_tokens = 123,
    seed = 42,
    stop = "###",
    n = 2,
    presence_penalty = 0.4,
    frequency_penalty = 0.2,
    logprobs = TRUE
  )

  captured <- NULL
  testthat::local_mocked_bindings(
    params = function(...) {
      captured <<- list(...)
      structure(list(...), class = "mock_ellmer_params")
    },
    .package = "ellmer"
  )

  params_obj <- llmModule:::bridge_params_from_config(prompt)

  testthat::expect_s3_class(params_obj, "mock_ellmer_params")
  testthat::expect_equal(captured$temperature, 0.7)
  testthat::expect_equal(captured$top_p, 0.9)
  testthat::expect_equal(captured$max_tokens, 123)
  testthat::expect_equal(captured$seed, 42)
  testthat::expect_equal(captured$stop_sequences, "###")
  testthat::expect_equal(captured$n, 2)
  testthat::expect_equal(captured$presence_penalty, 0.4)
  testthat::expect_equal(captured$frequency_penalty, 0.2)
  testthat::expect_equal(captured$log_probs, TRUE)
  testthat::expect_true(!is.null(captured$stop_sequences) || !is.null(captured$stop))
  testthat::expect_true(!is.null(captured$log_probs) || !is.null(captured$logprobs))
})

testthat::test_that("bridge_chat_create passes params only when supported by provider chat", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  params_obj <- structure(list(temperature = 0.5), class = "mock_ellmer_params")

  chat_with_params <- function(system_prompt = NULL, params = NULL, echo = NULL, ...) {
    testthat::expect_equal(params, params_obj)
    new.env(parent = emptyenv())
  }

  chat_without_params <- function(...) {
    dots <- list(...)
    testthat::expect_false("params" %in% names(dots))
    new.env(parent = emptyenv())
  }

  testthat::local_mocked_bindings(
    bridge_provider_function = function(prefix, provider) {
      if (prefix == "chat_") chat_with_params else NULL
    },
    .package = "llmModule"
  )
  llmModule:::bridge_chat_create(
    api = api,
    model = "claude-3-haiku",
    system_prompt = "system",
    params = params_obj
  )

  testthat::local_mocked_bindings(
    bridge_provider_function = function(prefix, provider) {
      if (prefix == "chat_") chat_without_params else NULL
    },
    .package = "llmModule"
  )
  llmModule:::bridge_chat_create(
    api = api,
    model = "claude-3-haiku",
    system_prompt = "system",
    params = params_obj
  )
})
