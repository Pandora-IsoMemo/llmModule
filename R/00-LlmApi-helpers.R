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

inspect_ellmer_auth_rules <- function() {
  ns <- asNamespace("ellmer")
  exports <- getNamespaceExports("ellmer")

  chat_fns <- sort(setdiff(grep("^chat_", exports, value = TRUE), "chat"))
  model_fns <- sort(grep("^models_", exports, value = TRUE))

  inspect_formals <- function(fn_name) {
    fn <- get(fn_name, envir = ns, inherits = FALSE)
    fm_names <- names(formals(fn))

    list(
      has_credentials = "credentials" %in% fm_names,
      has_api_key = "api_key" %in% fm_names
    )
  }

  chat_rows <- lapply(chat_fns, function(fn_name) {
    auth <- inspect_formals(fn_name)
    data.frame(
      provider_key = sub("^chat_", "", fn_name),
      chat_function = fn_name,
      chat_has_credentials_arg = auth$has_credentials,
      chat_has_api_key_arg = auth$has_api_key,
      stringsAsFactors = FALSE
    )
  })

  model_rows <- lapply(model_fns, function(fn_name) {
    auth <- inspect_formals(fn_name)
    data.frame(
      provider_key = sub("^models_", "", fn_name),
      models_function = fn_name,
      models_has_credentials_arg = auth$has_credentials,
      models_has_api_key_arg = auth$has_api_key,
      stringsAsFactors = FALSE
    )
  })

  chat_tbl <- if (length(chat_rows) > 0) {
    do.call(rbind, chat_rows)
  } else {
    data.frame(
      provider_key = character(0),
      chat_function = character(0),
      chat_has_credentials_arg = logical(0),
      chat_has_api_key_arg = logical(0),
      stringsAsFactors = FALSE
    )
  }

  model_tbl <- if (length(model_rows) > 0) {
    do.call(rbind, model_rows)
  } else {
    data.frame(
      provider_key = character(0),
      models_function = character(0),
      models_has_credentials_arg = logical(0),
      models_has_api_key_arg = logical(0),
      stringsAsFactors = FALSE
    )
  }

  out <- merge(chat_tbl, model_tbl, by = "provider_key", all = TRUE)

  out$chat_has_credentials_arg[is.na(out$chat_has_credentials_arg)] <- FALSE
  out$chat_has_api_key_arg[is.na(out$chat_has_api_key_arg)] <- FALSE
  out$models_has_credentials_arg[is.na(out$models_has_credentials_arg)] <- FALSE
  out$models_has_api_key_arg[is.na(out$models_has_api_key_arg)] <- FALSE

  out$auth_mode <- ifelse(
    out$chat_has_credentials_arg & out$chat_has_api_key_arg,
    "both",
    ifelse(
      out$chat_has_credentials_arg,
      "credentials_only",
      ifelse(out$chat_has_api_key_arg, "api_key_only", "ambient_or_provider_specific")
    )
  )

  out[order(out$provider_key), ]
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
#' function (if available), auth argument capabilities, and model argument rules.
#' Only providers with a chat `credentials` argument are included. Providers that
#' require an explicit model must also provide a models helper.
#'
#' @return A data frame with columns: provider_key, chat_function, models_function,
#'  model_rule, has_models_helper
#' @export
eligible_ellmer_providers <- function() {
  chat_tbl <- inspect_ellmer_chat_model_rules()
  models_tbl <- inspect_ellmer_models_helpers()
  auth_tbl <- inspect_ellmer_auth_rules()

  models_lookup <- stats::setNames(models_tbl$models_function, models_tbl$provider_key)

  chat_tbl$models_function <- unname(models_lookup[chat_tbl$provider_key])
  chat_tbl$has_models_helper <- !is.na(chat_tbl$models_function)

  chat_tbl$eligible <- (chat_tbl$model_rule != "required") |
    (chat_tbl$model_rule == "required" & chat_tbl$has_models_helper)

  chat_tbl$provider_name <- vapply(chat_tbl$provider_key, prettify_provider_key, character(1))

  chat_tbl <- merge(chat_tbl, auth_tbl, by = c("provider_key", "chat_function", "models_function"), all.x = TRUE)

  chat_tbl$chat_has_credentials_arg[is.na(chat_tbl$chat_has_credentials_arg)] <- FALSE
  chat_tbl$chat_has_api_key_arg[is.na(chat_tbl$chat_has_api_key_arg)] <- FALSE
  chat_tbl$models_has_credentials_arg[is.na(chat_tbl$models_has_credentials_arg)] <- FALSE
  chat_tbl$models_has_api_key_arg[is.na(chat_tbl$models_has_api_key_arg)] <- FALSE
  chat_tbl$auth_mode[is.na(chat_tbl$auth_mode)] <- "ambient_or_provider_specific"

  # Hard allowlist policy: chat must support explicit credentials.
  chat_tbl$eligible <- chat_tbl$eligible & chat_tbl$chat_has_credentials_arg

  # Set provider_name as row names for easy lookup and return only relevant columns
  rownames(chat_tbl) <- chat_tbl$provider_name

  chat_tbl[chat_tbl$eligible, c(
    "provider_name",
    "provider_key",
    "chat_function",
    "models_function",
    "model_rule",
    "has_models_helper",
    "auth_mode",
    "chat_has_credentials_arg",
    "chat_has_api_key_arg",
    "models_has_credentials_arg",
    "models_has_api_key_arg"
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
  # Normalize to ellmer bridge key style, e.g. "OpenRouter" -> "openrouter",
  # "Google Gemini" -> "google_gemini"
  key <- normalize_provider_key(provider)

  # Baseline that is widely safe across bridged ellmer providers
  base <- c("model", "messages", "max_tokens", "temperature", "top_p", "stop", "seed")

  # Additive capability hints by provider key
  # Keep this conservative; extend only when verified
  add_by_key <- list(
    anthropic = "n",
    openrouter = "n",
    groq = "n",
    mistral = "n",
    github = "n",
    google_gemini = "n",
    google_vertex = "n",
    aws_bedrock = "n",
    lmstudio = "n",
    vllm = "n",
    portkey = "n",
    ollama = character(0)
  )

  extra <- add_by_key[[key]]
  if (is.null(extra)) {
    # Unknown bridged provider: keep permissive default currently used in app
    extra <- "n"
  }

  unique(c(base, extra))
}

normalize_provider_key <- function(provider) {
  key <- tolower(gsub("[^A-Za-z0-9]+", "_", trimws(provider)))
  gsub("^_+|_+$", "", key)
}

ellmer_provider_model_rule <- function(provider) {
  key <- normalize_provider_key(provider)

  rules <- inspect_ellmer_chat_model_rules()
  idx <- match(key, rules$provider_key)

  if (is.na(idx)) {
    return("required")
  }

  rules$model_rule[[idx]]
}

ellmer_provider_has_models_helper <- function(provider) {
  key <- normalize_provider_key(provider)
  models <- inspect_ellmer_models_helpers()
  key %in% models$provider_key
}

ellmer_provider_models_support_credentials <- function(provider) {
  key <- normalize_provider_key(provider)
  auth <- inspect_ellmer_auth_rules()
  idx <- match(key, auth$provider_key)

  if (is.na(idx)) {
    return(FALSE)
  }

  isTRUE(auth$models_has_credentials_arg[[idx]])
}

ellmer_provider_can_list_models_with_credentials <- function(provider) {
  ellmer_provider_has_models_helper(provider) &&
    ellmer_provider_models_support_credentials(provider)
}

ellmer_model_can_fallback <- function(provider) {
  !identical(ellmer_provider_model_rule(provider), "required")
}

# Append attribute to object
append_attr <- function(object, val, attr_name) {
  existing <- attr(object, attr_name)
  attr(object, attr_name) <- c(existing, val)
  object
}
