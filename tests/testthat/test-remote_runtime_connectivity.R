testthat::test_that("new_RemoteLlmApi defers connectivity checks to runtime", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-validkey12345678901234567890", key_file)

  api <- new_RemoteLlmApi(
    api_key_path = key_file,
    provider = "OpenAI",
    no_internet = TRUE
  )

  testthat::expect_s3_class(api, "RemoteLlmApi")
  testthat::expect_s3_class(api, "LlmApi")
  testthat::expect_null(attr(api, "error"))
})

testthat::test_that("get_llm_models.RemoteLlmApi returns empty list when offline", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-validkey12345678901234567890", key_file)

  api <- new_RemoteLlmApi(
    api_key_path = key_file,
    provider = "OpenAI",
    no_internet = TRUE
  )

  testthat::expect_warning(
    models <- get_llm_models(api),
    "No connection! Check your internet connection."
  )

  testthat::expect_equal(models, list())
})

testthat::test_that("send_prompt.RemoteLlmApi returns connection error when offline", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-validkey12345678901234567890", key_file)

  api <- new_RemoteLlmApi(
    api_key_path = key_file,
    provider = "OpenAI",
    no_internet = TRUE
  )

  prompt <- new_LlmPromptConfig(
    prompt_content = "hello",
    model = "gpt-4.1"
  )

  result <- send_prompt(api, prompt)
  testthat::expect_equal(attr(result, "error"), "No connection! Check your internet connection.")
})
