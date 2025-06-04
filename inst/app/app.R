library(llmModule)


ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("LLM Prompt Module Test"),
  llm_single_prompt_ui("single_prompt")
)

server <- function(input, output, session) {
  llm_single_prompt_server("single_prompt")
}

shinyApp(ui, server)
