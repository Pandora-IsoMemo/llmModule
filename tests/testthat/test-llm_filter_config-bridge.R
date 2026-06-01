testthat::test_that("llm_filter_config keeps legacy provider behavior for OpenAI", {
  api <- list(provider = "OpenAI")
  class(api) <- c("RemoteLlmApi", "LlmApi")

  config <- new_LlmPromptConfig(
    prompt_content = "hello",
    model = "gpt-4.1",
    temperature = 0.5,
    max_tokens = 42,
    presence_penalty = 0.3,
    frequency_penalty = 0.1,
    logprobs = TRUE
  )

  filtered <- llmModule:::llm_filter_config(api, config)

  testthat::expect_true(all(c("presence_penalty", "frequency_penalty", "logprobs") %in% names(filtered)))
})

testthat::test_that("llm_filter_config uses bridge capability set for Ellmer providers", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")

  config <- new_LlmPromptConfig(
    prompt_content = "hello",
    model = "claude-3-haiku",
    temperature = 0.5,
    max_tokens = 42,
    presence_penalty = 0.3,
    frequency_penalty = 0.1,
    logprobs = TRUE
  )

  testthat::expect_warning(
    filtered <- llmModule:::llm_filter_config(api, config),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_false("presence_penalty" %in% names(filtered))
  testthat::expect_false("frequency_penalty" %in% names(filtered))
  testthat::expect_false("logprobs" %in% names(filtered))
  testthat::expect_true(all(c("model", "messages", "temperature", "max_tokens", "top_p", "n", "stop", "seed") %in% names(filtered)))
})

testthat::test_that("send_prompt.EllmerLlmApi emits unsupported-field warning from filter", {
  api <- llmModule:::new_EllmerLlmApi(provider = "Anthropic", api_key = "sk-ant-validkey123456789012345")
  prompt <- new_LlmPromptConfig(
    prompt_content = "Hello bridge",
    model = "claude-3-haiku",
    presence_penalty = 0.5,
    frequency_penalty = 0.4,
    logprobs = TRUE
  )

  fake_chat_obj <- new.env(parent = emptyenv())
  fake_chat_obj$chat <- function(prompt) list(raw = prompt)

  testthat::local_mocked_bindings(
    bridge_chat_create = function(api, model, system_prompt, params) fake_chat_obj,
    bridge_chat_send = function(chat_obj, prompt) list(turn = prompt),
    bridge_extract_text = function(turn) "ok",
    .package = "llmModule"
  )

  testthat::expect_warning(
    result <- send_prompt(api, prompt),
    "ignored for provider 'Anthropic'"
  )

  testthat::expect_equal(result$choices[[1]]$message$content, "ok")
})
