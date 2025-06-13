testthat::test_that("Test llm_api_server with too short OpenAI key", {
  shiny::testServer(llm_api_server,
                    args = list(
                      no_internet = NULL,
                      exclude_pattern = ""
                    ),
                    {
                      # Arrange
                      print("test llm_api_server: OpenAI provider with valid key file")

                      # Act
                      session$setInputs(
                        provider = "OpenAI",
                        api_key_file = structure(
                          list(
                            name = "test-importData_rgpt_validKeyFormat.txt",
                            size = 10L,
                            type = "text/plain",
                            datapath = testthat::test_path("test-gpt_key_too_short.txt")
                          ),
                          class = "data.frame",
                          row.names = c(NA, -1L)
                        )
                      )
                      testthat::expect_equal(api(), structure(list(), error = "API key appears too short."))
                    })
})

testthat::test_that("Test llm_api_server with OpenAI key", {
  shiny::testServer(llm_api_server,
                    args = list(
                      no_internet = NULL,
                      exclude_pattern = ""
                    ),
                    {
                      # Arrange
                      print("test llm_api_server: OpenAI provider with valid key file")

                      # Act
                      session$setInputs(
                        provider = "OpenAI",
                        api_key_file = structure(
                          list(
                            name = "test-importData_rgpt_validKeyFormat.txt",
                            size = 10L,
                            type = "text/plain",
                            datapath = testthat::test_path("test-gpt_key_format_ok.txt")
                          ),
                          class = "data.frame",
                          row.names = c(NA, -1L)
                        )
                      )

                      testthat::expect_true(inherits(api(), "RemoteLlmApi"))
                      testthat::expect_equal(api()$provider, "OpenAI")
                      testthat::expect_equal(api()$url_models , c(OpenAI = "https://api.openai.com/v1/models"))
                    })
})
