library(llmModule)


ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("LLM Prompt Module Test"),
  llm_generate_prompt_ui("single_prompt", outputResponse = TRUE)
)

server <- function(input, output, session) {
  llm_generate_prompt_server("single_prompt")
}

shinyApp(ui, server)
