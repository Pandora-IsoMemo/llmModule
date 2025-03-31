# ---- UI Function ----
llm_api_ui <- function(id, title = NULL) {
  ns <- NS(id)

  tagList(
    if (!is.null(title)) h3(title) else NULL,
    fluidRow(
      column(3, radioButtons(ns("provider"), "Choose Provider", choices = c("OpenAI", "DeepSeek"))),
      column(4, fileInput(ns("api_key_file"), "Upload API Key File", accept = c(".txt"))),
      column(5, align = "right", status_message_ui(ns("api_status")))
    ),
  )
}

# ---- Server Function ----
llm_api_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Reactive values
    api <- reactiveVal(NULL)

    observe({
      req(input$provider, input$api_key_file)

      # Call new_LlmApi with structured result
      result <- new_LlmApi(
        api_key_path = input$api_key_file$datapath,
        provider = input$provider
      )

      # Update reactive values
      api(result)
    }) |>
      bindEvent(input$api_key_file)

    statusMessageServer(
      "api_status",
      object = api,
      success_message = "Connection test successful!",
      error_message = "Connection test failed!"
    )

    # Return reactive values
    return(api)
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM API Test App"),
#   sidebarLayout(
#     sidebarPanel(
#       llm_api_ui("llm")
#     ),
#     mainPanel(
#       verbatimTextOutput("api")
#     )
#   )
# )
#
# server <- function(input, output, session) {
#   llm_api <- llm_api_server("llm")
#
#   output$api <- renderPrint({
#     llm_api()
#   })
# }
#
# shinyApp(ui, server)
