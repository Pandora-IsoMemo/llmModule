testthat::test_that("get_llm_models_info.RemoteLlmApi returns metadata with empty status when offline", {
  api <- new_RemoteLlmApi(
    api_key = "sk-validkey12345678901234567890",
    provider = "OpenAI",
    no_internet = TRUE
  )

  testthat::expect_warning(
    info <- get_llm_models_info(api),
    "No connection! Check your internet connection."
  )

  testthat::expect_s3_class(info, "LlmModelsInfo")
  testthat::expect_equal(info$models, list())
  testthat::expect_false(info$can_fallback_to_provider_default)
  testthat::expect_true(info$requires_explicit_model)
  testthat::expect_equal(info$listing_status, "empty")
  testthat::expect_equal(info$provider, "OpenAI")
})

testthat::test_that("get_llm_models_info.EllmerLlmApi marks unavailable listing when creds-only listing is unsupported", {
  api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key = "sk-ant-validkey123456789012345"
  )

  testthat::local_mocked_bindings(
    ellmer_provider_can_list_models_with_credentials = function(provider) FALSE,
    ellmer_model_can_fallback = function(provider) TRUE,
    .package = "llmModule"
  )

  info <- llmModule::get_llm_models_info(api, with_creds_only = TRUE)

  testthat::expect_s3_class(info, "LlmModelsInfo")
  testthat::expect_equal(info$models, list())
  testthat::expect_true(info$can_fallback_to_provider_default)
  testthat::expect_false(info$requires_explicit_model)
  testthat::expect_equal(info$listing_status, "unavailable")
  testthat::expect_equal(info$provider, "Anthropic")
})

testthat::test_that("get_llm_models_info.EllmerLlmApi reports non-empty model status", {
  api <- llmModule:::new_EllmerLlmApi(
    provider = "Anthropic",
    api_key = "sk-ant-validkey123456789012345"
  )

  testthat::local_mocked_bindings(
    get_llm_models.EllmerLlmApi = function(x, with_creds_only = TRUE, ...) c("model-a", "model-b"),
    ellmer_provider_can_list_models_with_credentials = function(provider) TRUE,
    ellmer_model_can_fallback = function(provider) FALSE,
    .package = "llmModule"
  )

  info <- llmModule::get_llm_models_info(api, with_creds_only = TRUE)

  testthat::expect_s3_class(info, "LlmModelsInfo")
  testthat::expect_equal(info$models, c("model-a", "model-b"))
  testthat::expect_false(info$can_fallback_to_provider_default)
  testthat::expect_true(info$requires_explicit_model)
  testthat::expect_equal(info$listing_status, "ok")
})
