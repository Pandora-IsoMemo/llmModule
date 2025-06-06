# ---- UI Function ----
llm_model_selector_ui <- function(id, label = "Select a Model") {
  ns <- NS(id)
  tagList(
    selectInput(ns("model"), label, choices = c("Check provider ..." = ""))
  )
}

# ---- Server Function ----
llm_model_selector_server <- function(id, api_reactive) {
  moduleServer(id, function(input, output, session) {
    observe({
      api <- api_reactive()

      if (inherits(api, "LlmApi")) {
        models <- get_llm_models(api)
      } else {
        models <- list()
      }
      # or get models from local installation?

      choices <- if (length(models) == 0) {
        c("No models found..." = "")
      } else {
        models
      }

      updateSelectInput(session, "model", choices = choices)
    }) |> bindEvent(api_reactive())

    # return selected model
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
