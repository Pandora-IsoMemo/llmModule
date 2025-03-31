# ---- Fetcher ----

#' Retrieve Available LLM Models
#'
#' The get_llm_models() function fetches a list of available models from a specified
#' Large Language Model (LLM) API, such as OpenAI's GPT models or DeepSeek models.
#' It requires an LlmApi object for authentication and returns the available model options.
#'
#' This function allows users to dynamically query OpenAI and DeepSeek to determine which models
#' are accessible while ensuring valid authentication via the LlmApi class.
#'
#' @param api an object of class LlmApi, created using the new_LlmApi() function, containing the API key and endpoint URL.
#'
#' @return A response object containing a list of available models from the selected API. This includes model IDs, descriptions, and other metadata.
#'
#' @examples
#' \dontrun{
#' # Create API credentials for DeepSeek
#' api <- new_LlmApi(api_key_path = "path/to/deepseek_key.txt", provider = "DeepSeek")
#'
#' # Retrieve available models from DeepSeek
#' models <- get_llm_models(api)
#'
#' # Create API credentials for OpenAI
#' api <- new_LlmApi(api_key_path = "path/to/openai_key.txt", provider = "OpenAI")
#'
#' # Retrieve available models from OpenAI
#' models <- get_llm_models(api)
#' }
get_llm_models <- function(api) {
  if (!inherits(api, "LlmApi")) return(list())

  req <- request(api$url_models) |>
    req_headers(Authorization = paste("Bearer", api$api_key),
                `Content-Type` = "application/json")

  content <- try_send_request(req)

  # Extract categories
  categories <- vapply(content$data, function(x) categorize_model(x$id), character(1))
  models <- vapply(content$data, function(x) x$id, character(1))

  # format into named list
  models_list <- split(models, categories)

  # order list by category, start with models "GPT*" in decreasing order of version then other categories
  models_list <- models_list[order_categories(categories)]

  return(models_list)
}

try_send_request <- function(request) {
  request_base <- tryCatch({
    # Send request
    request |> req_perform()
  }, error = function(e) {
    return(list(error = "API request failed", message = e$message))
  })

  request_content <- tryCatch({
    # Parse response
    request_base |> resp_body_json()
  }, error = function(e) {
    code <- "API parsing failed"
    warning(paste0(code, e$message))
    list(error = code, message = e$message)
  })

  if (!is.null(request_base$status_code) &&
      request_base$status_code != 200) {
    code <- paste0("Request completed with error. Code: ",
                   request_base$status_code)
    if (!is.null(request_content$error)) {
      message <- paste0(", message: ", request_content$error$message)
    } else {
      message <- NULL
    }

    warning(paste0(code, message))
  }

  return(request_content)
}

categorize_model <- function(id) {
  if (grepl("^gpt-[0-9.]+", id)) {
    match <- regmatches(id, regexpr("^gpt-[0-9.]+", id))
    return(toupper(match))  # Return as "GPT-4", "GPT-3.5", etc.
  }
  if (grepl("davinci|curie|babbage|ada", id)) return("GPT-3")
  if (grepl("embedding", id)) return("Embedding")
  if (grepl("whisper|speech", id)) return("Audio")
  if (grepl("dall-e|image", id)) return("Image")
  return("Other")
}

order_categories <- function(categories) {
  # Extract unique category names
  unique_cats <- unique(categories)

  # Separate GPT-* from others
  gpt_cats <- grep("^GPT-[0-9.]+", unique_cats, value = TRUE)
  other_cats <- setdiff(unique_cats, gpt_cats)

  # Sort GPT categories by descending version number
  # Convert "GPT-4" → 4.0, "GPT-3.5" → 3.5
  gpt_versions <- as.numeric(sub("GPT-", "", gpt_cats))
  ordered_gpt <- gpt_cats[order(-gpt_versions)] # decreasing

  # Final category order
  ordered_categories <- c(ordered_gpt, sort(other_cats))

  ordered_categories
}

# ---- UI Function ----
llm_model_selector_ui <- function(id, label = "Select a Model") {
  ns <- NS(id)

  selectInput(ns("model"), label, choices = c("Upload an API key..." = ""))
}

# ---- Server Function ----
llm_model_selector_server <- function(id, api_reactive) {
  moduleServer(id, function(input, output, session) {
    observe({
      api <- api_reactive()
      models <- get_llm_models(api)

      choices <- if (length(models) == 0) {
        c("Check your API key..." = "")
      } else {
        models
      }

      updateSelectInput(session, "model", choices = choices)
    }) |> bindEvent(api_reactive())

    # Optional: return selected model
    reactive(input$model)
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM Model Selector Test"),
#   llm_api_ui("llm"),
#   llm_model_selector_ui("model_picker"),
#   verbatimTextOutput("selected_model")
# )
#
# server <- function(input, output, session) {
#   llm_api <- llm_api_server("llm")
#
#   output$api <- renderPrint({
#     llm_api()
#   })
#
#   selected_model <- llm_model_selector_server("model_picker", llm_api)
#
#   output$selected_model <- renderPrint({
#     selected_model()
#   })
# }
#
# shinyApp(ui, server)
