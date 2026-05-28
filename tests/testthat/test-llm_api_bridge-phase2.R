testthat::test_that("send_prompt.EllmerLlmApi normalizes bridge output", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key_path = key_file)
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Bridge says hello",
    .package = "llmModule"
  )

  result <- send_prompt(api, prompt)

  testthat::expect_equal(result$choices[[1]]$message$role, "assistant")
  testthat::expect_equal(result$choices[[1]]$message$content, "Bridge says hello")
})

testthat::test_that("new_LlmResponse works with normalized Ellmer bridge response", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key_path = key_file)
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "claude-3-haiku")

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "Normalized content",
    .package = "llmModule"
  )

  response <- new_LlmResponse(api, prompt)

  testthat::expect_s3_class(response, "LlmResponse")
  testthat::expect_equal(response$generated_text, "Normalized content")
})

testthat::test_that("send_prompt.EllmerLlmApi returns structured error when model missing", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("token.alpha-1234:provider_key_567890", key_file)

  api <- llmModule:::new_EllmerLlmApi(provider = "Gemini", api_key_path = key_file)
  prompt <- new_LlmPromptConfig(prompt_content = "Hello bridge", model = "placeholder")
  prompt$model <- NULL

  result <- send_prompt(api, prompt)
  testthat::expect_equal(attr(result, "error"), "No model specified for Ellmer bridge request.")
})

testthat::test_that("get_llm_models.EllmerLlmApi categorizes extracted ids", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key_path = key_file)

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
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key_path = key_file,
    model = "claude-3-haiku"
  )

  testthat::local_mocked_bindings(
    bridge_models_list = function(api) stop("simulated model endpoint failure"),
    .package = "llmModule"
  )

  models <- get_llm_models(api)
  testthat::expect_equal(models, "claude-3-haiku")
})
