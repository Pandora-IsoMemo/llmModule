# ---- UI Function ----

llm_single_prompt_ui <- function(id,
                                 prompt_beginning = "\"Write an SQL query to ...\"",
                                 prompt_placeholder = "... your natural language instructions") {
  ns <- NS(id)

  tagList(
    llm_api_ui(ns("api")),
    llm_prompt_settings_ui(ns("prompt_settings")),
    div(style = "margin-bottom: 0.5em;",
        tags$html(
          HTML(sprintf("<b>Prompt Input:</b> &nbsp;&nbsp; %s", prompt_beginning))
        )),
    shinyAce::aceEditor(
      ns("prompt"),
      value = NULL,
      mode = "text",
      theme = "cobalt",
      fontSize = 16,
      autoScrollEditorIntoView = TRUE,
      minLines = 3,
      maxLines = 5,
      autoComplete = "live",
      placeholder = prompt_placeholder
    )
  )
}

# ---- Server Function ----

llm_single_prompt_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    llm_api <- llm_api_server("api")
    prompt_settings_reactive <- llm_prompt_settings_server("prompt_settings", llm_api, reactive(input$prompt))

    reactive({
      prompt_settings_reactive()
    })
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM Prompt Module Test"),
#   llm_single_prompt_ui("single_prompt"),
#   verbatimTextOutput("out")
# )
#
# server <- function(input, output, session) {
#   result <- llm_single_prompt_server("single_prompt")
#
#   output$out <- renderPrint({
#     result()
#   })
# }
#
# shinyApp(ui, server)
