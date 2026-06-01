testthat::test_that("send_prompt.EllmerLlmApi normalizes bridge output", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Bridge says hello",
    .package = "llmModule"
  )

  testthat::expect_warning(
    result <- send_prompt(api, prompt),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_equal(result$choices[[1]]$message$role, "assistant")
  testthat::expect_equal(result$choices[[1]]$message$content, "Bridge says hello")
})

testthat::test_that("new_LlmResponse works with normalized Ellmer bridge response", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Normalized content",
    .package = "llmModule"
  )

  testthat::expect_warning(
    response <- new_LlmResponse(api, prompt),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_s3_class(response, "LlmResponse")
  testthat::expect_equal(response$generated_text, "Normalized content")
})

testthat::test_that("send_prompt.EllmerLlmApi returns structured error when model missing", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Gemini", api_key = "token.alpha-1234:provider_key_567890")
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "placeholder")
  prompt$model <- NULL

  testthat::expect_warning(
    result <- send_prompt(api, prompt),
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

  models <- get_llm_models(api)

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

  models <- get_llm_models(api)
  testthat::expect_equal(models, "claude-3-haiku")
})
