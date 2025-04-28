library(llmModule)

ui <- fluidPage(
  titlePanel("Test App for Ollama Model Manager"),

  sidebarLayout(
    sidebarPanel(
      textInput("model_name", "Enter model name:", value = "tinyllama"),
      actionButton("go", "Check and Pull Model"),
      br(),
      textOutput("status_message")
    ),

    mainPanel(
      h3("Model Information"),
      verbatimTextOutput("model_info"),

      h3("Local Models (Manager)"),
      verbatimTextOutput("manager_info")
    )
  )
)

server <- function(input, output, session) {

  # Initialize manager once
  manager <- reactiveVal({
    mgr <- new_OllamaModelManager()
    mgr <- update(mgr)
    mgr
  })

  # Store pulled model
  model_obj <- reactiveVal(NULL)

  # Status message
  status_message <- reactiveVal("")

  observeEvent(input$go, {
    req(input$model_name)

    mgr <- manager()

    # 2. Clean user input
    model_to_use <- llmModule:::clean_model_name(mgr, input$model_name)

    # 3. Check if available (optional feedback)
    available <- llmModule:::is_model_available(mgr, model_to_use)

    if (available) {
      status_message(sprintf("Model '%s' is already available locally.", model_to_use))
    } else {
      status_message(sprintf("Model '%s' not available locally. Pulling...", model_to_use))
    }

    # 4. Pull if needed
    res <- llmModule:::pull_model_if_needed(mgr, model_to_use)
    mgr <- res$manager
    model <- res$model

    # Update reactives
    manager(mgr)
    model_obj(model)
  })

  output$status_message <- renderText({
    status_message()
  })

  output$model_info <- renderPrint({
    req(model_obj())
    print(model_obj())
  })

  output$manager_info <- renderPrint({
    req(manager())
    print(manager())
  })
}

shinyApp(ui, server)
