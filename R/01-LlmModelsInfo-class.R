new_LlmModelsInfo <- function(models = list(),
                              can_fallback_to_provider_default = FALSE,
                              requires_explicit_model = TRUE,
                              listing_status = c("ok", "empty", "error", "unavailable"),
                              provider = NULL) {
  listing_status <- match.arg(listing_status)

  structure(
    list(
      models = models,
      can_fallback_to_provider_default = isTRUE(can_fallback_to_provider_default),
      requires_explicit_model = isTRUE(requires_explicit_model),
      listing_status = listing_status,
      provider = provider
    ),
    class = "LlmModelsInfo"
  )
}