running_in_docker <- function() {
  file.exists("/.dockerenv")
}

running_in_shinyproxy <- function() {
  tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"
}

.onLoad <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    Sys.setenv(OLLAMA_BASE_URL = "http://host.docker.internal:11434")
  }
}

.onAttach <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    packageStartupMessage(sprintf("[%s] Docker environment detected; OLLAMA_BASE_URL set to host.docker.internal.", pkgname))
  }
}
