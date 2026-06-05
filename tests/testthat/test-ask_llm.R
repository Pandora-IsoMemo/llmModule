testthat::test_that("ask_llm routes Ollama requests through new_LocalLlmApi", {
  local_args <- NULL
  bridged_called <- FALSE

  testthat::local_mocked_bindings(
    new_LocalLlmApi = function(...) {
      local_args <<- list(...)
      structure(list(path = "local"), class = c("LocalLlmApi", "LlmApi"))
    },
    new_BridgedLlmApi = function(...) {
      bridged_called <<- TRUE
      structure(list(path = "bridge"), class = c("RemoteLlmApi", "LlmApi"))
    },
    new_LlmPromptConfig = function(...) structure(list(...), class = "LlmPromptConfig"),
    send_prompt = function(api, prompt_config) {
      list(api = api, prompt_config = prompt_config)
    },
    .package = "llmModule"
  )

  result <- llmModule:::ask_llm(
    provider = "Ollama",
    model = "llama3.1",
    prompt_content = "hello",
    new_model = "llama3.1"
  )

  testthat::expect_false(bridged_called)
  testthat::expect_equal(local_args$new_model, "llama3.1")
  testthat::expect_equal(result$api$path, "local")
})


testthat::test_that("ask_llm keeps legacy-vs-bridge routing inside new_BridgedLlmApi", {
  seen_classes <- list()

  testthat::local_mocked_bindings(
    new_LlmPromptConfig = function(...) structure(list(...), class = "LlmPromptConfig"),
    send_prompt = function(api, prompt_config) {
      seen_classes[[length(seen_classes) + 1]] <<- class(api)
      list(ok = TRUE)
    },
    .package = "llmModule"
  )

  llmModule:::ask_llm(
    provider = "OpenAI",
    api_key = "sk-validkey12345678901234567890",
    model = "gpt-4.1",
    prompt_content = "legacy route",
    no_internet = TRUE
  )

  llmModule:::ask_llm(
    provider = "Anthropic",
    api_key = "sk-ant-validkey123456789012345",
    model = "claude-3-haiku",
    prompt_content = "bridge route"
  )

  testthat::expect_true("RemoteLlmApi" %in% seen_classes[[1]])
  testthat::expect_true("EllmerLlmApi" %in% seen_classes[[2]])
})


testthat::test_that("ask_llm forwards ... into new_LlmPromptConfig", {
  captured_prompt_args <- NULL

  testthat::local_mocked_bindings(
    new_BridgedLlmApi = function(...) {
      structure(list(path = "bridge"), class = c("RemoteLlmApi", "LlmApi"))
    },
    new_LlmPromptConfig = function(...) {
      captured_prompt_args <<- list(...)
      structure(captured_prompt_args, class = "LlmPromptConfig")
    },
    send_prompt = function(api, prompt_config) list(ok = TRUE),
    .package = "llmModule"
  )

  llmModule:::ask_llm(
    provider = "OpenAI",
    api_key = "sk-validkey12345678901234567890",
    model = "gpt-4.1",
    prompt_content = "forward dots",
    temperature = 0.25,
    max_tokens = 77,
    stop = "###",
    seed = 42
  )

  testthat::expect_equal(captured_prompt_args$prompt_content, "forward dots")
  testthat::expect_equal(captured_prompt_args$model, "gpt-4.1")
  testthat::expect_equal(captured_prompt_args$temperature, 0.25)
  testthat::expect_equal(captured_prompt_args$max_tokens, 77)
  testthat::expect_equal(captured_prompt_args$stop, "###")
  testthat::expect_equal(captured_prompt_args$seed, 42)
})


testthat::test_that("ask_llm propagates API constructor errors", {
  prompt_builder_called <- FALSE
  sender_called <- FALSE

  bad_api <- list()
  attr(bad_api, "error") <- "api construction failed"

  testthat::local_mocked_bindings(
    new_BridgedLlmApi = function(...) bad_api,
    new_LlmPromptConfig = function(...) {
      prompt_builder_called <<- TRUE
      structure(list(...), class = "LlmPromptConfig")
    },
    send_prompt = function(api, prompt_config) {
      sender_called <<- TRUE
      list(ok = TRUE)
    },
    .package = "llmModule"
  )

  result <- llmModule:::ask_llm(
    provider = "OpenAI",
    api_key = "sk-validkey12345678901234567890",
    model = "gpt-4.1",
    prompt_content = "hello"
  )

  testthat::expect_equal(attr(result, "error"), "api construction failed")
  testthat::expect_false(prompt_builder_called)
  testthat::expect_false(sender_called)
})


testthat::test_that("ask_llm propagates prompt validation errors", {
  sender_called <- FALSE

  bad_prompt <- list()
  attr(bad_prompt, "error") <- "Model cannot be an empty string."

  testthat::local_mocked_bindings(
    new_BridgedLlmApi = function(...) {
      structure(list(path = "bridge"), class = c("RemoteLlmApi", "LlmApi"))
    },
    new_LlmPromptConfig = function(...) bad_prompt,
    send_prompt = function(api, prompt_config) {
      sender_called <<- TRUE
      list(ok = TRUE)
    },
    .package = "llmModule"
  )

  result <- llmModule:::ask_llm(
    provider = "OpenAI",
    api_key = "sk-validkey12345678901234567890",
    model = "",
    prompt_content = "hello"
  )

  testthat::expect_equal(attr(result, "error"), "Model cannot be an empty string.")
  testthat::expect_false(sender_called)
})


testthat::test_that("ask_llm surfaces new_LlmPromptConfig argument errors", {
  testthat::local_mocked_bindings(
    new_LocalLlmApi = function(...) {
      structure(list(path = "local"), class = c("LocalLlmApi", "LlmApi"))
    },
    .package = "llmModule"
  )

  testthat::expect_error(
    llmModule:::ask_llm(
      provider = "Ollama",
      model = "llama3.1",
      prompt_content = "hello",
      unsupported_field = 1
    ),
    "(unused|unbenutztes).*(argument|Argument)"
  )
})
