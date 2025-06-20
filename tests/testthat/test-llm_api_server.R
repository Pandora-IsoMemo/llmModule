testthat::test_that("Test llm_api_server with too short OpenAI key", {
  shiny::testServer(llm_api_server,
                    args = list(no_internet = NULL, exclude_pattern = ""),
                    {
                      # Arrange
                      print("test llm_api_server: OpenAI provider with valid key file")

                      # Act
                      session$setInputs(
                        provider = "OpenAI",
                        api_key_file = structure(
                          list(
                            name = "test-key",
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
                    args = list(no_internet = NULL, exclude_pattern = ""),
                    {
                      # Arrange
                      print("test llm_api_server: OpenAI provider with valid key file")

                      # Act
                      session$setInputs(
                        provider = "OpenAI",
                        api_key_file = structure(
                          list(
                            name = "test-key",
                            size = 10L,
                            type = "text/plain",
                            datapath = testthat::test_path("test-gpt_key_invalid.txt")
                          ),
                          class = "data.frame",
                          row.names = c(NA, -1L)
                        )
                      )

                      testthat::expect_equal(
                        api(),
                        structure(list(), error = "API request failed: Unauthorized: API key is invalid or expired.\n• OAuth error\n• realm: OpenAI API")
                      )
                    })
})
