#' LlmModelsInfo class
#' 
#' This class encapsulates information about available LLM models from a provider, including metadata about model selection and fallback behavior.
#' 
#' @param models A character vector or named list of available models.
#' @param can_fallback_to_provider_default Logical indicating if selecting no explicit model can fall back to a provider default.
#' @param listing_status Character indicating the status of the model listing (e.g., "ok", "empty", "error", "unavailable").
#' @param provider Character name of the provider.
#' @export
new_LlmModelsInfo <- function(models = list(),
                              can_fallback_to_provider_default = FALSE,
                              listing_status = c("ok", "empty", "error", "unavailable"),
                              provider = NULL) {
  listing_status <- match.arg(listing_status)

  structure(
    list(
      models = models,
      can_fallback_to_provider_default = isTRUE(can_fallback_to_provider_default),
      listing_status = listing_status,
      provider = provider
    ),
    class = "LlmModelsInfo"
  )
}

#' Check if an object is of class LlmModelsInfo
#'
#' @param x An object to check.
#' @return Logical scalar indicating if the object is an LlmModelsInfo.
#' @export
is_LlmModelsInfo <- function(x) {
  inherits(x, "LlmModelsInfo")
}

validate_LlmModelsInfo <- function(x) {
  if (!is_LlmModelsInfo(x)) {
    stop("Expected an LlmModelsInfo object.", call. = FALSE)
  }

  required_fields <- c(
    "models",
    "can_fallback_to_provider_default",
    "listing_status",
    "provider"
  )

  if (!all(required_fields %in% names(x))) {
    stop("LlmModelsInfo object is missing required fields.", call. = FALSE)
  }

  valid_status <- c("ok", "empty", "error", "unavailable")
  if (!is.character(x$listing_status) || length(x$listing_status) != 1 || !(x$listing_status %in% valid_status)) {
    stop("Invalid listing_status in LlmModelsInfo object.", call. = FALSE)
  }

  invisible(TRUE)
}

#' Create an empty LlmModelsInfo object
#'
#' This function creates an LlmModelsInfo object with an empty model list and specified provider and listing status.
#'
#' @param provider Character name of the provider (optional).
#' @param listing_status Character indicating the status of the model listing (default is "empty").
#' @return An LlmModelsInfo object with no models and specified metadata.
#' @export
new_empty_LlmModelsInfo <- function(provider = NULL, listing_status = "empty") {
  new_LlmModelsInfo(
    models = list(),
    can_fallback_to_provider_default = FALSE,
    listing_status = listing_status,
    provider = provider
  )
}

#' Extract model choices from LlmModelsInfo
#'
#' Returns the `models` element from an `LlmModelsInfo` object after validation.
#'
#' @param x An `LlmModelsInfo` object.
#' @return Character vector or named list of model choices.
#' @export
as_model_choices <- function(x) {
  validate_LlmModelsInfo(x)
  x$models
}

#' Check whether provider-default model fallback is allowed
#'
#' Returns whether an `LlmModelsInfo` object indicates that selecting no explicit
#' model can fall back to a provider default.
#'
#' @param x An `LlmModelsInfo` object.
#' @return Logical scalar.
#' @export
llm_models_can_fallback <- function(x) {
  validate_LlmModelsInfo(x)
  isTRUE(x$can_fallback_to_provider_default)
}