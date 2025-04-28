running_in_docker <- function() {
  file.exists("/.dockerenv")
}

running_in_shinyproxy <- function() {
  tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "true"
}

ollama_host_reachable <- function(url = "http://host.docker.internal:11434") {
  req <- request(url) |> req_timeout(1)

  tryCatch({
    resp <- req_perform(req)
    TRUE
  }, error = function(e) {
    FALSE
  })
}

.onLoad <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    if (ollama_host_reachable()) {
      Sys.setenv(OLLAMA_BASE_URL = "http://host.docker.internal:11434")
    }
  }
}

.onAttach <- function(libname, pkgname) {
  if (running_in_docker() && !running_in_shinyproxy()) {
    if (ollama_host_reachable()) {
      packageStartupMessage(sprintf("[%s] Docker detected: using OLLAMA_BASE_URL = host.docker.internal.", pkgname))
    } else {
      packageStartupMessage(sprintf(
        "[%s] Docker detected, but 'host.docker.internal' is not reachable. Cannot set OLLAMA_BASE_URL. Did you forget to add the host when running the container? Please use: 'docker run --add-host=host.docker.internal:host-gateway your-image'?",
        pkgname
      ))
    }
  }
}
