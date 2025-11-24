test_that("clean_error_message removes ANSI and trims whitespace", {
  msg <- "\033[31mError: Something went wrong\033[0m   "
  cleaned <- clean_error_message(msg)
  expect_equal(cleaned, "Error: Something went wrong")
})

test_that("clean_error_message replaces patterns", {
  msg <- "HTTP 401 Unauthorized: Invalid key"
  cleaned <- clean_error_message(msg, replace_text = c("HTTP 401 Unauthorized" = "Unauthorized: API key is invalid or expired"))
  expect_equal(cleaned, "Unauthorized: API key is invalid or expired: Invalid key")
})

test_that("clean_error_message handles empty replace_text", {
  msg <- "Some error occurred"
  cleaned <- clean_error_message(msg)
  expect_equal(cleaned, "Some error occurred")
})
