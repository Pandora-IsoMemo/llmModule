running_in_docker <- function() {
  file.exists("/.dockerenv")
}

running_in_shinyproxy <- function() {
  tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"
}

.onLoad <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    ollama_url <- Sys.getenv("OLLAMA_API_URL", unset = "http://localhost:11434")
  } else {
    ollama_url <- "http://localhost:11434"
  }

  Sys.setenv(OLLAMA_BASE_URL = ollama_url)
}

.onAttach <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    ollama_url <- Sys.getenv("OLLAMA_API_URL", unset = "http://localhost:11434")
    packageStartupMessage(sprintf("[%s] Docker detected: using OLLAMA_BASE_URL = '%s'.", pkgname, ollama_url))
  } else {
    packageStartupMessage(sprintf("[%s] Default setup: using OLLAMA_BASE_URL = 'http://localhost:11434'.", pkgname))
  }
}
