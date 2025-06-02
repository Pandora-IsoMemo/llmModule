# ---- UI Function ----

llm_single_prompt_ui <- function(id,
                                 prompt_beginning = "",
                                 prompt_placeholder = "Ask me anything...",
                                 theme = "xcode") {
  ns <- NS(id)

  tagList(
    llm_api_ui(ns("api")),
    tags$br(),
    llm_prompt_settings_ui(ns("prompt_settings")),
    div(style = "margin-bottom: 0.5em;",
        tags$html(
          HTML(sprintf("<b>Prompt Input:</b> &nbsp;&nbsp; %s", prompt_beginning))
        )),
    shinyAce::aceEditor(
      ns("prompt"),
      value = NULL,
      mode = "text",
      theme = theme,
      fontSize = 16,
      autoScrollEditorIntoView = TRUE,
      minLines = 3,
      maxLines = 5,
      autoComplete = "live",
      placeholder = prompt_placeholder
    ),
    fluidRow(
      column(4, actionButton(ns("generate"), "Generate Text")),
      column(8, align = "right", status_message_ui(ns("response_status"))),

    ),
    hr(),
    verbatimTextOutput(ns("generated_text"))
  )
}

# ---- Server Function ----

llm_single_prompt_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    llm_api_reactive <- llm_api_server("api")
    prompt_settings_reactive <- llm_prompt_settings_server("prompt_settings", llm_api_reactive, reactive(input$prompt))

    llm_response <- reactiveVal()

    # disable generate button if no API key is available
    observe({
      if (!inherits(llm_api_reactive(), "LlmApi") || !inherits(prompt_settings_reactive(), "LlmPromptSettings")) {
        shinyjs::disable(ns("generate"), asis = TRUE)
      } else {
        shinyjs::enable(ns("generate"), asis = TRUE)
      }
    })

    observe({
      new_response <- new_LlmResponse(llm_api_reactive(), prompt_settings_reactive())
      llm_response(new_response)
    }) |>
      bindEvent(input$generate)

    statusMessageServer(
      "response_status",
      object = llm_response,
      success_message = "Response ready!",
      warning_message = "Response incomplete.",
      error_message   = "Response generation failed."
    )

    output$generated_text <- renderPrint({
      validate(need(inherits(llm_response(), "LlmResponse"), "No response available."))

      response_table <- llm_response() |> as_table(output_type = "text")
      response_table$core_output$content |> cat()
    })

    return(llm_response)
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   shinyjs::useShinyjs(),
#   titlePanel("LLM Prompt Module Test"),
#   llm_single_prompt_ui("single_prompt")
# )
#
# server <- function(input, output, session) {
#   llm_single_prompt_server("single_prompt")
# }
#
# shinyApp(ui, server)
