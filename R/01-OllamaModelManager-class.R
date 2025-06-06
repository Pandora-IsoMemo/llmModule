#' Ollama Model Manager
#'
#' Manages the listing, checking, and pulling of Ollama models.
#'
#' @return An object of class OllamaModelManager
#' @export
new_OllamaModelManager <- function() {

  manager <- structure(
    list(
      local_models = NULL  # will cache pulled models (updated on demand)
    ),
    class = "OllamaModelManager"
  )

  return(manager)
}

#' Print method for OllamaModelManager
#'
#' @param x An OllamaModelManager object
#' @param ... Additional arguments
#' @export
print.OllamaModelManager <- function(x, ...) {
  cat("Ollama Model Manager\n")
  if (!is.null(x$local_models)) {
    cat("Local Models:\n")
    cat(paste0("- ", x$local_models), sep = "\n")
  } else {
    cat("No local models cached yet. Call update(x).\n")
  }
}

#' Update the list of locally available models
#'
#' @param x An OllamaModelManager object
#' @param ... Not used, for compatibility
#' @return Updated OllamaModelManager object
#' @export
update.OllamaModelManager <- function(x, ...) {
  models <- tryCatch(
    list_models(host = Sys.getenv("OLLAMA_BASE_URL")),
    error = function(e) {
      warning("Could not fetch local models. Is the Ollama server running?")
      return(data.frame())
    }
  )

  x$local_models <- models$name

  return(x)
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("Test App for Ollama Model Manager"),
#
#   sidebarLayout(
#     sidebarPanel(
#       textInput("model_name", "Enter model name:", value = "tinyllama"),
#       actionButton("go", "Check and Pull Model"),
#       br(),
#       textOutput("status_message")
#     ),
#
#     mainPanel(
#       h3("Model Information"),
#       verbatimTextOutput("model_info"),
#
#       h3("Local Models (Manager)"),
#       verbatimTextOutput("manager_info")
#     )
#   )
# )
#
# server <- function(input, output, session) {
#
#   # Initialize manager once
#   manager <- reactiveVal({
#     mgr <- new_OllamaModelManager()
#     mgr <- update(mgr)
#     mgr
#   })
#
#   # Store pulled model
#   model_obj <- reactiveVal(NULL)
#
#   # Status message
#   status_message <- reactiveVal("")
#
#   observeEvent(input$go, {
#     req(input$model_name)
#
#     mgr <- manager()
#
#     # 2. Clean user input
#     model_to_use <- llmModule:::clean_model_name(mgr, input$model_name)
#
#     # 3. Check if available (optional feedback)
#     available <- llmModule:::is_model_available(mgr, model_to_use)
#
#     if (available) {
#       status_message(sprintf("Model '%s' is already available locally.", model_to_use))
#     } else {
#       status_message(sprintf("Model '%s' not available locally. Pulling...", model_to_use))
#     }
#
#     # 4. Pull if needed
#     res <- llmModule:::pull_model_if_needed(mgr, model_to_use)
#     mgr <- res$manager
#     model <- res$model
#
#     # Update reactives
#     manager(mgr)
#     model_obj(model)
#   })
#
#   output$status_message <- renderText({
#     status_message()
#   })
#
#   output$model_info <- renderPrint({
#     req(model_obj())
#     print(model_obj())
#   })
#
#   output$manager_info <- renderPrint({
#     req(manager())
#     print(manager())
#   })
# }
#
# shinyApp(ui, server)
#
