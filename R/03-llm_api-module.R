# ---- UI Function ----
llm_api_ui <- function(id, title = NULL) {
  ns <- NS(id)

  is_shinyproxy <- tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"

  provider_choices <- c("OpenAI" = "OpenAI", "DeepSeek" = "DeepSeek")
  if (!is_shinyproxy) {
    provider_choices <- c(provider_choices, "Ollama (Local)" = "Ollama")
  }

  tagList(
    if (!is.null(title)) h3(title) else NULL,
    fluidRow(
      column(3, radioButtons(ns("provider"), "Choose Provider", choices = provider_choices, selected = character(0))),
      conditionalPanel(
        ns = ns,
        condition = "input.provider != 'Ollama'",
        column(4, fileInput(ns("api_key_file"), "Upload API Key File", accept = c(".txt")))
      ),
      conditionalPanel(
        ns = ns,
        condition = "input.provider == 'Ollama'",
        column(4,
               textInput(ns("new_model"), "Pull model", placeholder = "tinyllama"),
               actionButton(ns("pull_ollama"), "Pull"))
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

    # Initialize manager
    manager <- reactiveVal(NULL)
    if (!is_shinyproxy) {
      manager(update(new_OllamaModelManager()))
    }


    # Cache the uploaded API key path (only when a new file is uploaded)
    api_key_path <- reactive({
      input$api_key_file$datapath
    })

    # Trigger remote API creation when file is uploaded
    remote_api <- reactive({
      req(input$provider %in% c("OpenAI", "DeepSeek"))
      if (!is.null(input$api_key_file)) {
        new_RemoteLlmApi(api_key_path = input$api_key_file$datapath, provider = input$provider)
      } else {
        new_RemoteLlmApi(provider = input$provider)
      }
    })

    # Trigger local API creation when pull button is clicked
    local_api <- eventReactive(input$pull_ollama, {
      req(!is_shinyproxy, input$new_model)
      new_LocalLlmApi(manager(), input$new_model)
    })

    # Default to initializing Ollama if selected (no pull)
    observeEvent(input$provider, {
      if (!is_shinyproxy && input$provider == "Ollama") {
        api(new_LocalLlmApi(manager()))
      }
    })

    # Watch the remote and local API creators and update the shared reactiveVal
    observeEvent(remote_api(), {
      api(remote_api())
    })

    observeEvent(local_api(), {
      api(local_api())
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
