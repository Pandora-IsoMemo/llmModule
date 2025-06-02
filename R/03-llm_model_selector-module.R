# ---- UI Function ----
llm_model_selector_ui <- function(id, label = "Select a Model") {
  ns <- NS(id)
  tagList(
    # radioButtons(ns("source"), "Model source", choices = c("API", "Local"), inline = TRUE),
    #
    # re-organize UI for source <--> provider
    # if API: -> API key file
    # if local: check load models UI
    # for both: select a model
    # later: pass the selected model to the prompt settings module
    # remove the selection from the prompt settings module
    selectInput(ns("model"), label, choices = c("Upload an API key..." = ""))
  )
}

# ---- Server Function ----
llm_model_selector_server <- function(id, api_reactive) {
  moduleServer(id, function(input, output, session) {
    get_local_models <- reactive({
      manager <- new_OllamaModelManager()
      manager <- update(manager)
      manager$local_models
    })

    get_api_models <- reactive({
      api <- api_reactive()
      if (!inherits(api, "LlmApi")) return(character(0))
      get_llm_models(api)
    })

    # observe({
    #   models <- switch(input$source,
    #                    "API" = get_api_models(api_reactive()),
    #                    "Local" = get_local_models(),
    #                    character(0)
    #   )
    #
    #   choices <- if (length(models) == 0) {
    #     c("No models found..." = "")
    #   } else {
    #     models
    #   }
    #
    #   updateSelectInput(session, "model", choices = choices)
    # }) |> bindEvent(input$source, api_reactive())
    #
    # # Output: selected model + source
    # reactive(list(
    #   source = input$source,
    #   model = input$model
    # ))

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
