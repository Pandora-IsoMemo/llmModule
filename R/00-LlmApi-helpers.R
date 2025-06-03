categorize_model <- function(id) {
  if (grepl("^gpt-[0-9.]+", id)) {
    match <- regmatches(id, regexpr("^gpt-[0-9.]+", id))
    return(toupper(match))  # Return as "GPT-4", "GPT-3.5", etc.
  }
  if (grepl("davinci|curie|babbage|ada", id)) return("GPT-3")
  if (grepl("embedding", id)) return("Embedding")
  if (grepl("whisper|speech", id)) return("Audio")
  if (grepl("dall-e|image", id)) return("Image")
  return("Other")
}

# order list by category, start with models "GPT*" in decreasing order of version then other categories
order_categories <- function(categories) {
  # Extract unique category names
  unique_cats <- unique(categories)

  # Separate GPT-* from others
  gpt_cats <- grep("^GPT-[0-9.]+", unique_cats, value = TRUE)
  other_cats <- setdiff(unique_cats, gpt_cats)

  # Sort GPT categories by descending version number
  # Convert "GPT-4" → 4.0, "GPT-3.5" → 3.5
  gpt_versions <- as.numeric(sub("GPT-", "", gpt_cats))
  ordered_gpt <- gpt_cats[order(-gpt_versions)] # decreasing

  # Final category order
  ordered_categories <- c(ordered_gpt, sort(other_cats))

  ordered_categories
}

extract_named_model_list <- function(models, categories) {
  if (all(unique(categories) %in% c("Other"))) {
    return(models)
  }

  # format into named list
  models_list <- split(models, categories)

  # order list by category, start with models "GPT*" in decreasing order of version then other categories
  models_list <- models_list[order_categories(categories)]

  return(models_list)
}

llm_filter_config <- function(api, config) {
  provider <- api$provider  # e.g., "OpenAI", "DeepSeek", "Ollama"

  supported <- switch(
    provider,
    "OpenAI" = c("model", "messages", "temperature", "top_p", "n", "stop", "seed", "max_tokens",
                 "presence_penalty", "frequency_penalty", "logprobs"),
    "DeepSeek" = c("model", "messages", "temperature", "top_p", "n", "stop", "seed", "max_tokens"),
    "Ollama" = c("model", "messages", "temperature", "top_p", "stop", "seed", "max_tokens"),
    character(0)
  )

  all_fields <- names(config)
  unsupported <- setdiff(all_fields, supported)

  result <- config[names(config) %in% supported]

  if (length(unsupported) > 0) {
    warning_msg <- sprintf("The following inputs are ignored for provider '%s': %s",
                           provider,
                           paste(unsupported, collapse = ", "))
    result <- append_attr(result, warning_msg, "message")
  }

  return(result)
}
