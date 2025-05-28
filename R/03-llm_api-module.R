# ---- UI Function ----
llm_api_ui <- function(id, title = NULL) {
  ns <- NS(id)

  is_shinyproxy <- tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"

  provider_choices <- c("OpenAI", "DeepSeek")
  if (!is_shinyproxy) {
    provider_choices <- c(provider_choices, "Local (Ollama)")
  }

  tagList(
    if (!is.null(title)) h3(title) else NULL,
    fluidRow(
      column(3, radioButtons(ns("provider"), "Choose Provider", choices = provider_choices, selected = character(0))),
      conditionalPanel(
        ns = ns,
        condition = "input.provider != 'Local (Ollama)'",
        column(4, fileInput(ns("api_key_file"), "Upload API Key File", accept = c(".txt")))
      ),
      conditionalPanel(
        ns = ns,
        condition = "input.provider == 'Local (Ollama)'",
        column(4, uiOutput(ns("ollama_model_ui")))
      ),
      column(5, align = "right", status_message_ui(ns("api_status")))
    ),
  )
}

# ---- Server Function ----
llm_api_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    # Reactive values
    api <- reactiveVal(NULL)
    is_shinyproxy <- tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"

    manager <- reactiveVal(NULL)
    if (!is_shinyproxy) {
      manager(update(new_OllamaModelManager()))
    }

    observeEvent(input$provider, {
      if (!is_shinyproxy && input$provider == "Local (Ollama)") {
        models <- manager()$local_models
        output$ollama_model_ui <- renderUI({
          selectInput(ns("ollama_model"), "Select Local Model", choices = models)
        })
      }
    })

    observe({
      req(input$provider)

      if (input$provider == "Local (Ollama)") {
        req(input$ollama_model)
        api(new_LocalLlmApi(input$ollama_model, manager()))
      } else {
        req(input$api_key_file)
        api(new_RemoteLlmApi(
          api_key_path = input$api_key_file$datapath,
          provider = input$provider
        ))
      }
    })

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
