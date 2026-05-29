testthat::test_that("new_BridgedLlmApi routes OpenAI and DeepSeek to legacy RemoteLlmApi path", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-validkey12345678901234567890", key_file)

  openai_api <- llmModule:::new_BridgedLlmApi(
    provider = "OpenAI",
    api_key_path = key_file,
    no_internet = TRUE
  )
  testthat::expect_s3_class(openai_api, "RemoteLlmApi")
  testthat::expect_s3_class(openai_api, "LlmApi")

  deepseek_api <- llmModule:::new_BridgedLlmApi(
    provider = "DeepSeek",
    api_key_path = key_file,
    no_internet = TRUE
  )
  testthat::expect_s3_class(deepseek_api, "RemoteLlmApi")
  testthat::expect_s3_class(deepseek_api, "LlmApi")
})

testthat::test_that("legacy remote bridge checks connectivity at runtime", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-validkey12345678901234567890", key_file)

  openai_api <- llmModule:::new_BridgedLlmApi(
    provider = "OpenAI",
    api_key_path = key_file,
    no_internet = TRUE
  )

  testthat::expect_warning(
    models <- get_llm_models(openai_api),
    "No connection! Check your internet connection."
  )
  testthat::expect_equal(models, list())

  prompt <- new_LlmPromptConfig(prompt_content = "hello", model = "gpt-4.1")
  result <- send_prompt(openai_api, prompt)
  testthat::expect_equal(attr(result, "error"), "No connection! Check your internet connection.")
})

testthat::test_that("new_BridgedLlmApi routes non-legacy providers to Ellmer bridge", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  api <- llmModule:::new_BridgedLlmApi(
    provider = "Anthropic",
    api_key_path = key_file
  )

  testthat::expect_s3_class(api, "EllmerLlmApi")
  testthat::expect_s3_class(api, "LlmApi")
  testthat::expect_equal(api$provider, "Anthropic")
  testthat::expect_equal(api$bridge, "ellmer")
})

testthat::test_that("Ellmer bridge validates provider-specific key prefixes", {
  valid_key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", valid_key_file)

  valid_api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key_path = valid_key_file
  )
  testthat::expect_s3_class(valid_api, "EllmerLlmApi")

  invalid_key_file <- tempfile(fileext = ".txt")
  writeLines("wrongprefix-validkey123456789012345", invalid_key_file)

  invalid_api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key_path = invalid_key_file
  )
  testthat::expect_equal(
    attr(invalid_api, "error"),
    "API key does not match the selected provider 'Anthropic'."
  )
})

testthat::test_that("Ellmer bridge enforces one-line key file structure", {
  key_file <- tempfile(fileext = ".txt")
  writeLines(c("line1", "line2"), key_file)

  api <- llmModule:::new_EllmerLlmApi(
    provider = "Gemini",
    api_key_path = key_file
  )

  testthat::expect_equal(
    attr(api, "error"),
    "Wrong format. The file should only contain one line with the key."
  )
})

testthat::test_that("Ellmer bridge rejects short keys", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("short-key", key_file)

  api <- llmModule:::new_EllmerLlmApi(
    provider = "Gemini",
    api_key_path = key_file
  )

  testthat::expect_equal(attr(api, "error"), "API key appears too short.")
})

testthat::test_that("Ellmer bridge accepts generic provider token structures", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("token.alpha-1234:provider_key_567890", key_file)

  api <- llmModule:::new_EllmerLlmApi(
    provider = "Gemini",
    api_key_path = key_file
  )

  testthat::expect_s3_class(api, "EllmerLlmApi")
  testthat::expect_null(attr(api, "error"))
})

testthat::test_that("Ellmer bridge rejects unsupported key characters", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("token with space 12345678901234567890", key_file)

  api <- llmModule:::new_EllmerLlmApi(
    provider = "Gemini",
    api_key_path = key_file
  )

  testthat::expect_equal(
    attr(api, "error"),
    "API key format contains unsupported characters."
  )
})
