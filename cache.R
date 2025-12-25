##########################
# Caching System for Data Transformations
# Improves performance by avoiding redundant computations
##########################

# Initialize cache environment
cache_env <- new.env()
cache_env$data <- list()
cache_env$metadata <- list()
cache_env$hits <- 0
cache_env$misses <- 0

##########################
# Cache Management Functions
##########################

# Generate cache key from parameters
generate_cache_key <- function(...) {
  params <- list(...)
  # Convert to string and hash
  key_string <- paste(capture.output(str(params)), collapse = "")

  # Use digest if available, otherwise use simple hash
  if (requireNamespace("digest", quietly = TRUE)) {
    key <- digest::digest(key_string, algo = "md5")
  } else {
    # Fallback: simple hash based on string
    key <- as.character(abs(sum(utf8ToInt(key_string)) %% 999999999))
  }
  return(key)
}

# Store data in cache
cache_set <- function(key, value, metadata = NULL) {
  if (!PERFORMANCE$enable_cache) {
    return(invisible(NULL))
  }

  cache_env$data[[key]] <- value
  cache_env$metadata[[key]] <- list(
    timestamp = Sys.time(),
    size_bytes = object.size(value),
    metadata = metadata
  )

  # Cleanup old entries if cache is too large
  cleanup_cache()

  invisible(value)
}

# Retrieve data from cache
cache_get <- function(key) {
  if (!PERFORMANCE$enable_cache) {
    return(NULL)
  }

  if (cache_has(key)) {
    # Check if cache entry is still valid
    meta <- cache_env$metadata[[key]]
    age_hours <- as.numeric(difftime(Sys.time(), meta$timestamp, units = "hours"))

    if (age_hours <= PERFORMANCE$cache_max_age_hours) {
      cache_env$hits <- cache_env$hits + 1
      return(cache_env$data[[key]])
    } else {
      # Cache expired, remove it
      cache_remove(key)
    }
  }

  cache_env$misses <- cache_env$misses + 1
  return(NULL)
}

# Check if key exists in cache
cache_has <- function(key) {
  return(key %in% names(cache_env$data))
}

# Remove specific key from cache
cache_remove <- function(key) {
  if (cache_has(key)) {
    cache_env$data[[key]] <- NULL
    cache_env$metadata[[key]] <- NULL
  }
  invisible(NULL)
}

# Clear entire cache
cache_clear <- function() {
  cache_env$data <- list()
  cache_env$metadata <- list()
  cache_env$hits <- 0
  cache_env$misses <- 0
  message("Cache cleared")
  invisible(NULL)
}

# Cleanup old or large cache entries
cleanup_cache <- function() {
  if (length(cache_env$data) == 0) {
    return(invisible(NULL))
  }

  # Remove expired entries
  current_time <- Sys.time()
  for (key in names(cache_env$metadata)) {
    meta <- cache_env$metadata[[key]]
    age_hours <- as.numeric(difftime(current_time, meta$timestamp, units = "hours"))

    if (age_hours > PERFORMANCE$cache_max_age_hours) {
      cache_remove(key)
    }
  }

  # Check total cache size
  total_size <- sum(sapply(cache_env$metadata, function(m) as.numeric(m$size_bytes)))
  max_size <- 500 * 1024^2  # 500 MB limit

  if (total_size > max_size) {
    # Remove oldest entries until under limit
    sorted_keys <- names(cache_env$metadata)[order(sapply(cache_env$metadata, function(m) m$timestamp))]

    for (key in sorted_keys) {
      cache_remove(key)
      total_size <- sum(sapply(cache_env$metadata, function(m) as.numeric(m$size_bytes)))

      if (total_size <= max_size) {
        break
      }
    }
    message(paste("Cache cleanup: removed entries to stay under", max_size / 1024^2, "MB"))
  }

  invisible(NULL)
}

# Get cache statistics
cache_stats <- function() {
  total_entries <- length(cache_env$data)
  total_size <- sum(sapply(cache_env$metadata, function(m) as.numeric(m$size_bytes)))
  hit_rate <- if ((cache_env$hits + cache_env$misses) > 0) {
    cache_env$hits / (cache_env$hits + cache_env$misses)
  } else {
    0
  }

  list(
    total_entries = total_entries,
    total_size_mb = round(total_size / 1024^2, 2),
    hits = cache_env$hits,
    misses = cache_env$misses,
    hit_rate = round(hit_rate * 100, 2)
  )
}

# Print cache statistics
print_cache_stats <- function() {
  stats <- cache_stats()
  cat("===== Cache Statistics =====\n")
  cat(sprintf("Total entries: %d\n", stats$total_entries))
  cat(sprintf("Total size: %.2f MB\n", stats$total_size_mb))
  cat(sprintf("Cache hits: %d\n", stats$hits))
  cat(sprintf("Cache misses: %d\n", stats$misses))
  cat(sprintf("Hit rate: %.2f%%\n", stats$hit_rate))
  cat("===========================\n")
}

##########################
# Cached Data Transformation Functions
##########################

# Cached data selection
cached_select_data <- function(data, prctvalues, selectmethod, NAstructure = FALSE, ...) {
  cache_key <- generate_cache_key("select_data", data, prctvalues, selectmethod, NAstructure, ...)

  cached_result <- cache_get(cache_key)
  if (!is.null(cached_result)) {
    message("✓ Using cached data selection")
    return(cached_result)
  }

  # Perform actual computation (call original function)
  result <- selectdata(data, prctvalues, selectmethod, NAstructure, ...)

  cache_set(cache_key, result, metadata = list(operation = "select_data"))
  return(result)
}

# Cached data transformation
cached_transform_data <- function(data, log = FALSE, logtype = "logn", standardization = FALSE,
                                   arcsin = FALSE, rempNA = "moy", ...) {
  cache_key <- generate_cache_key("transform_data", data, log, logtype, standardization, arcsin, rempNA, ...)

  cached_result <- cache_get(cache_key)
  if (!is.null(cached_result)) {
    message("✓ Using cached data transformation")
    return(cached_result)
  }

  # Perform actual computation
  result <- transformdata(data, log, logtype, standardization, arcsin, rempNA, ...)

  cache_set(cache_key, result, metadata = list(operation = "transform_data"))
  return(result)
}

# Cached statistical tests
cached_statistical_test <- function(data, test = "Wtest", thresholdFC = 0, thresholdpv = 0.05,
                                     adjustpv = FALSE, ...) {
  cache_key <- generate_cache_key("statistical_test", data, test, thresholdFC, thresholdpv, adjustpv, ...)

  cached_result <- cache_get(cache_key)
  if (!is.null(cached_result)) {
    message("✓ Using cached statistical test results")
    return(cached_result)
  }

  # Perform actual computation
  result <- switch(test,
                   "Wtest" = testdata(data, "wilcoxon", thresholdFC, thresholdpv, adjustpv),
                   "Ttest" = testdata(data, "student", thresholdFC, thresholdpv, adjustpv),
                   "lasso" = multivariateselection(data, method = "lasso", ...),
                   "elasticnet" = multivariateselection(data, method = "elasticnet", ...),
                   "ridge" = multivariateselection(data, method = "ridge", ...),
                   "clustEnet" = clustEnetSelection(data, ...),
                   list())

  cache_set(cache_key, result, metadata = list(operation = "statistical_test", test = test))
  return(result)
}

# Cached model training
cached_train_model <- function(data, model_type, ...) {
  # For models, we cache only if explicitly requested (models can be large)
  cache_models <- getOption("cache_models", FALSE)

  if (!cache_models) {
    # Don't cache models by default
    return(NULL)
  }

  cache_key <- generate_cache_key("train_model", data, model_type, ...)

  cached_result <- cache_get(cache_key)
  if (!is.null(cached_result)) {
    message(paste("✓ Using cached model:", model_type))
    return(cached_result)
  }

  return(NULL)  # Return NULL to indicate cache miss, caller should train model
}

# Store trained model in cache
cache_model <- function(model, data, model_type, ...) {
  cache_models <- getOption("cache_models", FALSE)

  if (!cache_models) {
    return(invisible(NULL))
  }

  cache_key <- generate_cache_key("train_model", data, model_type, ...)
  cache_set(cache_key, model, metadata = list(operation = "train_model", model_type = model_type))

  invisible(model)
}

##########################
# Memoization Decorator
##########################

# Create a memoized version of any function
memoize <- function(f) {
  cache <- new.env(parent = emptyenv())

  function(...) {
    key <- generate_cache_key(...)

    if (exists(key, envir = cache, inherits = FALSE)) {
      return(get(key, envir = cache))
    }

    result <- f(...)
    assign(key, result, envir = cache)
    result
  }
}

##########################
# Reactive Cache for Shiny
##########################

# Create reactive cache wrapper
reactive_cache <- function(reactive_expr, session, cache_key) {
  if (!PERFORMANCE$enable_cache) {
    return(reactive_expr)
  }

  # Check if cached result exists
  cached <- cache_get(cache_key)

  if (!is.null(cached)) {
    return(reactive(cached))
  }

  # Create reactive and cache result
  result <- reactive_expr

  # Observe and cache when value changes
  observe({
    value <- result()
    cache_set(cache_key, value)
  })

  return(result)
}

##########################
# File-based Cache (for persistence across sessions)
##########################

# Save cache to disk
save_cache_to_disk <- function(filepath = ".cache/cache.rds") {
  if (!dir.exists(dirname(filepath))) {
    dir.create(dirname(filepath), recursive = TRUE)
  }

  tryCatch({
    saveRDS(list(
      data = cache_env$data,
      metadata = cache_env$metadata,
      stats = list(hits = cache_env$hits, misses = cache_env$misses)
    ), filepath)
    message(paste("Cache saved to:", filepath))
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error saving cache:", e$message))
    return(FALSE)
  })
}

# Load cache from disk
load_cache_from_disk <- function(filepath = ".cache/cache.rds") {
  if (!file.exists(filepath)) {
    message("No cache file found")
    return(FALSE)
  }

  tryCatch({
    cache_data <- readRDS(filepath)
    cache_env$data <- cache_data$data
    cache_env$metadata <- cache_data$metadata
    cache_env$hits <- cache_data$stats$hits
    cache_env$misses <- cache_data$stats$misses

    # Cleanup expired entries
    cleanup_cache()

    message(paste("Cache loaded from:", filepath))
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error loading cache:", e$message))
    return(FALSE)
  })
}

##########################
# Initialize cache system
##########################

# Create cache directory if it doesn't exist
if (!dir.exists(PERFORMANCE$cache_dir)) {
  dir.create(PERFORMANCE$cache_dir, recursive = TRUE, showWarnings = FALSE)
}

# Try to load existing cache
if (PERFORMANCE$enable_cache) {
  load_cache_from_disk(file.path(PERFORMANCE$cache_dir, "cache.rds"))
  message("Cache system initialized")
}

# Setup cache cleanup on exit
reg.finalizer(cache_env, function(e) {
  if (PERFORMANCE$enable_cache) {
    save_cache_to_disk(file.path(PERFORMANCE$cache_dir, "cache.rds"))
  }
}, onexit = TRUE)
