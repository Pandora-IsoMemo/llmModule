is_valid_character <- function(string) {
  !missing(string) &&
    is.character(string) &&
    length(string) == 1 &&
    nzchar(trimws(string))
}

inspect_ellmer_chat_model_rules <- function() {
  ns <- asNamespace("ellmer")
  exports <- getNamespaceExports("ellmer")

  chat_fns <- grep("^chat_", exports, value = TRUE)
  chat_fns <- setdiff(chat_fns, "chat")
  chat_fns <- sort(chat_fns)

  required_model_sentinel <- alist(model = )

  inspect_one <- function(fn_name) {
    fn <- get(fn_name, envir = ns, inherits = FALSE)
    fm <- formals(fn)

    if (!("model" %in% names(fm))) {
      return(data.frame(
        chat_function = fn_name,
        provider_key = sub("^chat_", "", fn_name),
        model_rule = "no model argument",
        model_default = NA_character_,
        stringsAsFactors = FALSE
      ))
    }

    # Keep as pairlist to avoid forcing a missing-arg object
    model_formal <- fm["model"]

    if (identical(model_formal, required_model_sentinel)) {
      rule <- "required"
      def <- NA_character_
    } else {
      default_expr <- model_formal[[1]]

      if (is.null(default_expr)) {
        rule <- "optional with internal provider default"
        def <- "NULL"
      } else {
        rule <- "optional with explicit formal default"
        def <- paste(deparse(default_expr), collapse = " ")
      }
    }

    data.frame(
      chat_function = fn_name,
      provider_key = sub("^chat_", "", fn_name),
      model_rule = rule,
      model_default = def,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, lapply(chat_fns, inspect_one))
  rownames(out) <- NULL
  out
}

inspect_ellmer_models_helpers <- function() {
  exports <- getNamespaceExports("ellmer")
  model_fns <- sort(grep("^models_", exports, value = TRUE))
  data.frame(
    models_function = model_fns,
    provider_key = sub("^models_", "", model_fns),
    stringsAsFactors = FALSE
  )
}

prettify_provider_key <- function(provider_key) {
  key <- tolower(trimws(provider_key))

  # Known brand spellings and acronyms
  known <- c(
    "openai" = "OpenAI",
    "azure_openai" = "Azure OpenAI",
    "aws_bedrock" = "AWS Bedrock",
    "google_gemini" = "Google Gemini",
    "google_vertex" = "Google Vertex",
    "huggingface" = "Hugging Face",
    "deepseek" = "DeepSeek",
    "openrouter" = "OpenRouter",
    "github" = "GitHub",
    "lmstudio" = "LM Studio",
    "vllm" = "vLLM",
    "anthropic" = "Anthropic",
    "claude" = "Claude",
    "groq" = "Groq",
    "mistral" = "Mistral",
    "ollama" = "Ollama",
    "databricks" = "Databricks",
    "cloudflare" = "Cloudflare",
    "perplexity" = "Perplexity",
    "portkey" = "Portkey",
    "snowflake" = "Snowflake"
  )

  if (key %in% names(known)) {
    return(unname(known[[key]]))
  }

  # Fallback: foo_bar -> Foo Bar
  key <- gsub("_+", "_", key)
  parts <- strsplit(key, "_", fixed = TRUE)[[1]]
  parts <- parts[nzchar(parts)]

  if (!length(parts)) {
    return(provider_key)
  }

  parts <- paste0(toupper(substr(parts, 1, 1)), substr(parts, 2, nchar(parts)))
  paste(parts, collapse = " ")
}

#' Get eligible ellmer providers
#'
#' Returns a data frame of providers with their chat function, models helper
#' function (if available), and model argument rules. Only providers that have a
#' models helper function when required are included.
#'
#' @return A data frame with columns: provider_key, chat_function, models_function,
#'  model_rule, has_models_helper
#' @export
eligible_ellmer_providers <- function() {
  chat_tbl <- inspect_ellmer_chat_model_rules()
  models_tbl <- inspect_ellmer_models_helpers()

  models_lookup <- stats::setNames(models_tbl$models_function, models_tbl$provider_key)

  chat_tbl$models_function <- unname(models_lookup[chat_tbl$provider_key])
  chat_tbl$has_models_helper <- !is.na(chat_tbl$models_function)

  chat_tbl$eligible <- (chat_tbl$model_rule != "required") |
    (chat_tbl$model_rule == "required" & chat_tbl$has_models_helper)

  chat_tbl$provider_name <- vapply(chat_tbl$provider_key, prettify_provider_key, character(1))

  chat_tbl[chat_tbl$eligible, c(
    "provider_name",
    "provider_key",
    "chat_function",
    "models_function",
    "model_rule",
    "has_models_helper"
  )]
}

filter_model_list <- function(models, exclude_pattern) {
  if (is_valid_character(exclude_pattern)) {
    models <- models[!grepl(exclude_pattern, models)]
  }

  return(models)
}

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
  provider <- api$provider  # e.g., "OpenAI", "DeepSeek", "Ollama", or bridged providers
  supported <- llm_supported_fields(api)

  all_fields <- names(config)
  unsupported <- setdiff(all_fields, supported)

  result <- config[names(config) %in% supported]

  if (length(unsupported) > 0) {
    warning_msg <- sprintf("The following inputs are ignored for provider '%s': %s",
                           provider,
                           paste(unsupported, collapse = ", "))
    warning(warning_msg, call. = FALSE)
    #result <- append_attr(result, warning_msg, "message")
  }

  return(result)
}

llm_supported_fields <- function(api) {
  provider <- api$provider

  if (inherits(api, "EllmerLlmApi") || identical(api$bridge, "ellmer")) {
    return(llm_bridge_supported_fields(provider))
  }

  switch(
    provider,
    "OpenAI" = c("model", "messages", "max_tokens", "temperature", "top_p", "n", "stop", "seed",
                 "presence_penalty", "frequency_penalty", "logprobs"),
    "DeepSeek" = c("model", "messages", "max_tokens", "temperature", "top_p", "n", "stop", "seed"),
    "Ollama" = c("model", "messages", "max_tokens", "temperature", "top_p", "stop", "seed"),
    character(0)
  )
}

llm_bridge_supported_fields <- function(provider) {
  # Common bridged fields that map well across multiple ellmer providers.
  common <- c("model", "messages", "max_tokens", "temperature", "top_p", "n", "stop", "seed")

  provider_specific <- switch(
    provider,
    # Keep place for future provider-specific capability extensions.
    "Anthropic" = common,
    "OpenRouter" = common,
    "Groq" = common,
    "Mistral" = common,
    common
  )

  provider_specific
}

# Append attribute to object
append_attr <- function(object, val, attr_name) {
  existing <- attr(object, attr_name)
  attr(object, attr_name) <- c(existing, val)
  object
}
