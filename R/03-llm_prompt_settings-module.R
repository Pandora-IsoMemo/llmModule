# ---- UI Function ----
llm_prompt_config_ui <- function(id) {
  ns <- NS(id)

  # possibly load default values from config later ...
  fields_advanced_1 <- list(
    list(fun = selectInput, args = list(ns("prompt_role"), "Prompt Role", c("user", "system", "assistant"))),
    list(fun = numericInput, args = list(ns("seed"), "Seed (optional)", value = NA, min = 1, step = 1)),
    list(fun = numericInput, args = list(ns("n"), "No. of Completions (n)", value = 1, min = 1)),
    list(fun = textInput, args = list(ns("stop"), "Stop Sequence (optional)", placeholder = "e.g. ### or <end>"))
  )

  fields_advanced_2 <- list(
    list(fun = sliderInput, args = list(ns("top_p"), "Top-p", min = 0, max = 1, value = 1, step = 0.01)),
    list(fun = sliderInput, args = list(ns("presence_penalty"), "Presence Penalty", min = -2, max = 2, value = 0, step = 0.1)),
    list(fun = sliderInput, args = list(ns("frequency_penalty"), "Frequency Penalty", min = -2, max = 2, value = 0, step = 0.1)),
    list(fun = checkboxInput, args = list(ns("logprobs"), "Return Logprobs", value = FALSE))
  )

  tagList(
    fluidRow(
      column(3, llm_model_selector_ui(ns("model_picker"))),
      column(3, numericInput(ns("max_tokens"), "Max Tokens", value = 100, min = 1)),
      column(3, sliderInput(ns("temperature"), "Temperature", min = 0, max = 2, value = 1, step = 0.1)),
      column(3, checkboxInput(ns("show_advanced"), "Show Advanced Settings", value = FALSE))
    ),
    conditionalPanel(
      ns = ns,
      condition = "input.show_advanced == true",
      fluidRow(
        lapply(fields_advanced_1, function(f) column(3, do.call(f$fun, f$args)))
      ),
      fluidRow(
        lapply(fields_advanced_2, function(f) column(3, do.call(f$fun, f$args)))
      )
    ),
    fluidRow(
      column(12, align = "right", status_message_ui(ns("settings_status")))
    )
  )
}

# ---- Server Function ----
llm_prompt_config_server <- function(id, llm_api = reactiveVal(list()), prompt_reactive = reactiveVal("")) {
  moduleServer(id, function(input, output, session) {
    model_reactive <- llm_model_selector_server("model_picker", llm_api)

    llm_prompt_config <- reactiveVal()

    observe({
      new_settings <- new_LlmPromptConfig(
        prompt_content = prompt_reactive(),
        model = model_reactive(),
        prompt_role = input$prompt_role,
        seed = if (is.na(input$seed)) NULL else input$seed,
        max_tokens = input$max_tokens,
        temperature = input$temperature,
        top_p = input$top_p,
        n = input$n,
        stop = if (nzchar(input$stop)) input$stop else NULL,
        presence_penalty = input$presence_penalty,
        frequency_penalty = input$frequency_penalty,
        logprobs = input$logprobs
      )

      llm_prompt_config(new_settings)
    })

    statusMessageServer(
      "settings_status",
      object = llm_prompt_config,
      success_message = "Prompt settings ready!",
      warning_message = "Prompt settings incomplete.",
      error_message   = "Prompt settings invalid."
    )

    llm_prompt_config
  })
}


# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM Prompt Settings Module"),
#   llm_prompt_config_ui("llm_settings"),
#   verbatimTextOutput("params")
# )
#
# server <- function(input, output, session) {
#   prompt_config <- llm_prompt_config_server("llm_settings")
#
#   output$params <- renderPrint({
#     prompt_config()
#   })
# }
#
# shinyApp(ui, server)
