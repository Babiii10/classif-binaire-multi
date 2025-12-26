################################################################################
# PRESET CONFIGURATIONS MODULE
################################################################################
# Description: Predefined analysis configurations for common use cases
# Features:
#   - 6 preset configurations (Quick, Standard, Robust, Publication, Exploratory, Production)
#   - Complete workflow settings (preprocessing, feature selection, models, validation)
#   - Easy import/export of custom presets
#   - Automatic parameter optimization based on preset
#   - Time estimates for each preset
#
# Preset Types:
#   1. Quick: Fast exploratory analysis (~5 min)
#   2. Standard: Balanced speed/accuracy (~15 min)
#   3. Robust: High accuracy, thorough validation (~30 min)
#   4. Publication: Comprehensive analysis for papers (~60 min)
#   5. Exploratory: Try all methods (~45 min)
#   6. Production: Optimized for deployment (~20 min)
################################################################################

################################################################################
# PRESET DEFINITIONS
################################################################################

#' Get all available presets
#'
#' @return List of all preset configurations
get_all_presets <- function() {

  presets <- list(

    # ========== QUICK PRESET ==========
    quick = list(
      name = "Quick Analysis",
      description = "Fast exploratory analysis with basic models",
      time_estimate = "~5 minutes",
      use_case = "Initial data exploration, proof of concept",

      preprocessing = list(
        missing_values = "simple",  # mean/mode imputation
        missing_threshold = 0.3,    # remove vars with >30% missing
        log_transform = FALSE,
        standardization = FALSE,
        outlier_handling = "none"
      ),

      feature_selection = list(
        method = "none",  # skip feature selection
        n_features = NULL
      ),

      models = c("randomforest"),  # single fast model

      model_params = list(
        randomforest = list(
          ntree = 100,              # reduced trees
          mtry = NULL,              # auto
          nodesize = 10             # larger nodes = faster
        )
      ),

      validation = list(
        method = "holdout",
        train_ratio = 0.7,
        cv_folds = 3,               # minimal CV
        bootstrap_iterations = 10   # minimal bootstrap
      ),

      performance = list(
        enable_parallel = FALSE,
        enable_cache = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "none",            # skip balancing
        apply_to = "none"
      ),

      advanced = list(
        enable_ensemble = FALSE,
        enable_automl = FALSE,
        enable_interpretability = FALSE,
        generate_report = FALSE
      )
    ),

    # ========== STANDARD PRESET ==========
    standard = list(
      name = "Standard Analysis",
      description = "Balanced analysis with good accuracy and reasonable speed",
      time_estimate = "~15-20 minutes",
      use_case = "Regular classification tasks, general purpose",

      preprocessing = list(
        missing_values = "knn",     # KNN imputation
        missing_threshold = 0.2,
        log_transform = TRUE,
        standardization = TRUE,
        outlier_handling = "clip"   # clip to 3 SD
      ),

      feature_selection = list(
        method = "pvalue",
        n_features = 50,
        pvalue_threshold = 0.05
      ),

      models = c("randomforest", "xgboost", "elasticnet"),

      model_params = list(
        randomforest = list(
          ntree = 500,
          mtry = NULL,
          nodesize = 5
        ),
        xgboost = list(
          nrounds = 100,
          max_depth = 6,
          eta = 0.3
        ),
        elasticnet = list(
          alpha = 0.5,
          nlambda = 100
        )
      ),

      validation = list(
        method = "cv",
        train_ratio = 0.7,
        cv_folds = 5,
        bootstrap_iterations = 50
      ),

      performance = list(
        enable_parallel = TRUE,
        enable_cache = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "auto",            # auto-select based on severity
        apply_to = "train"
      ),

      advanced = list(
        enable_ensemble = TRUE,
        ensemble_method = "averaging",
        enable_automl = FALSE,
        enable_interpretability = TRUE,
        generate_report = TRUE
      )
    ),

    # ========== ROBUST PRESET ==========
    robust = list(
      name = "Robust Analysis",
      description = "High accuracy with thorough validation",
      time_estimate = "~30-40 minutes",
      use_case = "Critical applications, medical/financial domains",

      preprocessing = list(
        missing_values = "mice",    # Multiple imputation
        missing_threshold = 0.15,
        log_transform = TRUE,
        standardization = TRUE,
        outlier_handling = "remove" # remove outliers
      ),

      feature_selection = list(
        method = "pvalue",
        n_features = 100,
        pvalue_threshold = 0.01     # stricter threshold
      ),

      models = c("randomforest", "xgboost", "svm", "elasticnet"),

      model_params = list(
        randomforest = list(
          ntree = 1000,
          mtry = NULL,
          nodesize = 1
        ),
        xgboost = list(
          nrounds = 200,
          max_depth = 8,
          eta = 0.1               # slower learning
        ),
        svm = list(
          kernel = "radial",
          cost = 1,
          gamma = "auto"
        ),
        elasticnet = list(
          alpha = 0.5,
          nlambda = 200
        )
      ),

      validation = list(
        method = "cv",
        train_ratio = 0.7,
        cv_folds = 10,              # 10-fold CV
        bootstrap_iterations = 100,
        stratified = TRUE
      ),

      performance = list(
        enable_parallel = TRUE,
        enable_cache = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "smote",
        apply_to = "train"
      ),

      advanced = list(
        enable_ensemble = TRUE,
        ensemble_method = "stacking",
        enable_automl = TRUE,
        enable_interpretability = TRUE,
        enable_overfitting_detection = TRUE,
        generate_report = TRUE
      )
    ),

    # ========== PUBLICATION PRESET ==========
    publication = list(
      name = "Publication Ready",
      description = "Comprehensive analysis for research publications",
      time_estimate = "~60-90 minutes",
      use_case = "Academic papers, detailed research",

      preprocessing = list(
        missing_values = "mice",
        missing_threshold = 0.1,
        log_transform = TRUE,
        standardization = TRUE,
        outlier_handling = "analyze"  # detailed outlier analysis
      ),

      feature_selection = list(
        method = "combined",        # multiple methods
        n_features = 150,
        pvalue_threshold = 0.01
      ),

      models = c("randomforest", "xgboost", "svm", "elasticnet", "knn", "naivebayes"),

      model_params = list(
        randomforest = list(
          ntree = 2000,
          mtry = NULL,
          nodesize = 1,
          importance = TRUE
        ),
        xgboost = list(
          nrounds = 500,
          max_depth = 10,
          eta = 0.05
        ),
        svm = list(
          kernel = "radial",
          cost = 10,
          gamma = "auto"
        ),
        elasticnet = list(
          alpha = 0.5,
          nlambda = 500
        )
      ),

      validation = list(
        method = "nested_cv",       # nested cross-validation
        train_ratio = 0.7,
        cv_folds = 10,
        bootstrap_iterations = 200,
        stratified = TRUE,
        repeated_cv = 5             # 5 repetitions
      ),

      performance = list(
        enable_parallel = TRUE,
        enable_cache = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "hybrid",
        apply_to = "train"
      ),

      advanced = list(
        enable_ensemble = TRUE,
        ensemble_method = "stacking",
        enable_automl = TRUE,
        enable_interpretability = TRUE,
        interpretability_methods = c("shap", "permutation"),
        enable_overfitting_detection = TRUE,
        enable_data_validation = TRUE,
        generate_report = TRUE,
        export_models = TRUE,
        export_formats = c("rds", "pmml", "json")
      )
    ),

    # ========== EXPLORATORY PRESET ==========
    exploratory = list(
      name = "Exploratory Analysis",
      description = "Try multiple methods to find best approach",
      time_estimate = "~45-60 minutes",
      use_case = "New datasets, finding optimal approach",

      preprocessing = list(
        missing_values = "compare",  # try multiple methods
        missing_threshold = 0.2,
        log_transform = "auto",      # try with/without
        standardization = "auto",
        outlier_handling = "analyze"
      ),

      feature_selection = list(
        method = "all",              # try all methods
        n_features = c(20, 50, 100), # try multiple feature counts
        pvalue_threshold = 0.05
      ),

      models = c("randomforest", "xgboost", "svm", "elasticnet", "knn"),

      model_params = list(
        randomforest = list(
          ntree = c(100, 500, 1000),  # grid search
          mtry = NULL,
          nodesize = c(1, 5, 10)
        ),
        xgboost = list(
          nrounds = c(50, 100, 200),
          max_depth = c(4, 6, 8),
          eta = c(0.1, 0.3, 0.5)
        )
      ),

      validation = list(
        method = "cv",
        train_ratio = 0.7,
        cv_folds = 5,
        bootstrap_iterations = 100
      ),

      performance = list(
        enable_parallel = TRUE,
        enable_cache = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "compare",         # try multiple balancing methods
        apply_to = "train"
      ),

      advanced = list(
        enable_ensemble = TRUE,
        ensemble_method = c("voting", "averaging", "stacking"),  # try all
        enable_automl = TRUE,
        enable_interpretability = TRUE,
        generate_report = TRUE
      )
    ),

    # ========== PRODUCTION PRESET ==========
    production = list(
      name = "Production Optimized",
      description = "Optimized for deployment and inference speed",
      time_estimate = "~20-30 minutes",
      use_case = "Model deployment, production systems",

      preprocessing = list(
        missing_values = "simple",   # fast imputation
        missing_threshold = 0.2,
        log_transform = TRUE,
        standardization = TRUE,
        outlier_handling = "clip"
      ),

      feature_selection = list(
        method = "pvalue",
        n_features = 30,            # fewer features = faster inference
        pvalue_threshold = 0.01
      ),

      models = c("randomforest", "xgboost"),  # production-ready models

      model_params = list(
        randomforest = list(
          ntree = 200,              # balanced accuracy/speed
          mtry = NULL,
          nodesize = 5
        ),
        xgboost = list(
          nrounds = 100,
          max_depth = 6,
          eta = 0.3,
          tree_method = "hist"      # faster training
        )
      ),

      validation = list(
        method = "cv",
        train_ratio = 0.8,          # more training data
        cv_folds = 5,
        bootstrap_iterations = 50
      ),

      performance = list(
        enable_parallel = TRUE,
        enable_cache = TRUE,
        optimize_for_inference = TRUE
      ),

      imbalance = list(
        detect = TRUE,
        method = "auto",
        apply_to = "train"
      ),

      advanced = list(
        enable_ensemble = FALSE,    # single model for speed
        enable_automl = TRUE,
        automl_metric = "balanced_accuracy",  # focus on robustness
        enable_interpretability = FALSE,  # skip for production
        enable_overfitting_detection = TRUE,
        generate_report = TRUE,
        export_models = TRUE,
        export_formats = c("rds", "pmml")  # deployment formats
      )
    )
  )

  return(presets)
}

################################################################################
# PRESET SELECTION AND APPLICATION
################################################################################

#' Get specific preset configuration
#'
#' @param preset_name Name of preset ("quick", "standard", "robust", "publication", "exploratory", "production")
#' @return Preset configuration list
get_preset <- function(preset_name = "standard") {

  presets <- get_all_presets()

  if (!preset_name %in% names(presets)) {
    warning(paste("Unknown preset:", preset_name, "- using 'standard'"))
    preset_name <- "standard"
  }

  return(presets[[preset_name]])
}

#' Apply preset configuration to current session
#'
#' @param preset_name Preset name or custom preset list
#' @param override Optional list of parameters to override
#' @return Applied configuration
apply_preset <- function(preset_name = "standard", override = NULL) {

  # Get base preset
  if (is.character(preset_name)) {
    preset <- get_preset(preset_name)
  } else if (is.list(preset_name)) {
    preset <- preset_name
  } else {
    stop("preset_name must be character or list")
  }

  # Apply overrides
  if (!is.null(override)) {
    preset <- merge_configs(preset, override)
  }

  # Set global configuration (if config.R is loaded)
  if (exists("DEFAULT_PARAMS", envir = .GlobalEnv)) {
    message("Applying preset: ", preset$name)
    message("Description: ", preset$description)
    message("Estimated time: ", preset$time_estimate)
    message("")

    # Update global parameters
    assign("CURRENT_PRESET", preset, envir = .GlobalEnv)
  }

  return(preset)
}

#' Merge two configuration lists (override takes precedence)
merge_configs <- function(base, override) {

  for (key in names(override)) {
    if (is.list(override[[key]]) && is.list(base[[key]])) {
      base[[key]] <- merge_configs(base[[key]], override[[key]])
    } else {
      base[[key]] <- override[[key]]
    }
  }

  return(base)
}

################################################################################
# PRESET COMPARISON
################################################################################

#' Compare multiple presets
#'
#' @param preset_names Vector of preset names to compare
#' @return Data frame with comparison
compare_presets <- function(preset_names = c("quick", "standard", "robust")) {

  presets <- get_all_presets()

  comparison <- data.frame(
    Preset = character(),
    Time = character(),
    Models = character(),
    Validation = character(),
    Features = character(),
    Ensemble = character(),
    Use_Case = character(),
    stringsAsFactors = FALSE
  )

  for (name in preset_names) {
    if (name %in% names(presets)) {
      p <- presets[[name]]

      comparison <- rbind(comparison, data.frame(
        Preset = p$name,
        Time = p$time_estimate,
        Models = paste(p$models, collapse = ", "),
        Validation = p$validation$method,
        Features = as.character(p$feature_selection$n_features %||% "all"),
        Ensemble = as.character(p$advanced$enable_ensemble),
        Use_Case = p$use_case,
        stringsAsFactors = FALSE
      ))
    }
  }

  return(comparison)
}

#' Display preset comparison table
display_preset_comparison <- function() {

  comparison <- compare_presets(c("quick", "standard", "robust", "publication", "exploratory", "production"))

  message("\n=== PRESET COMPARISON ===\n")
  print(comparison, row.names = FALSE)
  message("\n========================\n")

  return(comparison)
}

################################################################################
# CUSTOM PRESETS
################################################################################

#' Save custom preset configuration
#'
#' @param preset Custom preset list
#' @param name Preset name
#' @param file_path Optional file path to save (default: presets/custom/)
save_custom_preset <- function(preset, name, file_path = NULL) {

  if (is.null(file_path)) {
    preset_dir <- "presets"
    if (!dir.exists(preset_dir)) {
      dir.create(preset_dir, recursive = TRUE)
    }
    file_path <- file.path(preset_dir, paste0(name, ".rds"))
  }

  saveRDS(preset, file_path)
  message("Custom preset saved to: ", file_path)

  return(file_path)
}

#' Load custom preset
#'
#' @param name Preset name or file path
#' @return Preset configuration
load_custom_preset <- function(name) {

  # Try as file path first
  if (file.exists(name)) {
    preset <- readRDS(name)
    message("Loaded custom preset from: ", name)
    return(preset)
  }

  # Try in presets directory
  preset_file <- file.path("presets", paste0(name, ".rds"))
  if (file.exists(preset_file)) {
    preset <- readRDS(preset_file)
    message("Loaded custom preset: ", name)
    return(preset)
  }

  stop("Custom preset not found: ", name)
}

#' Export preset to JSON
#'
#' @param preset_name Preset name
#' @param output_file Output JSON file
export_preset_to_json <- function(preset_name, output_file) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("JSON export requires 'jsonlite' package")
  }

  preset <- get_preset(preset_name)

  jsonlite::write_json(
    preset,
    path = output_file,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  message("Preset exported to JSON: ", output_file)
}

#' Import preset from JSON
#'
#' @param input_file Input JSON file
#' @return Preset configuration
import_preset_from_json <- function(input_file) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("JSON import requires 'jsonlite' package")
  }

  preset <- jsonlite::read_json(input_file, simplifyVector = TRUE)

  message("Preset imported from JSON: ", input_file)

  return(preset)
}

################################################################################
# PRESET RECOMMENDATIONS
################################################################################

#' Recommend preset based on dataset characteristics
#'
#' @param n_samples Number of samples
#' @param n_features Number of features
#' @param n_classes Number of classes
#' @param imbalance_ratio Class imbalance ratio
#' @param time_constraint Time constraint in minutes
#' @return Recommended preset name
recommend_preset <- function(n_samples, n_features, n_classes = 2,
                            imbalance_ratio = 1, time_constraint = NULL) {

  message("\n=== Preset Recommendation ===")
  message("Dataset: ", n_samples, " samples, ", n_features, " features, ", n_classes, " classes")
  message("Imbalance ratio: ", round(imbalance_ratio, 2), ":1")

  # Time-based recommendation
  if (!is.null(time_constraint)) {
    if (time_constraint <= 10) {
      message("Recommendation: 'quick' (time constraint: ", time_constraint, " min)")
      return("quick")
    } else if (time_constraint <= 25) {
      message("Recommendation: 'standard' (time constraint: ", time_constraint, " min)")
      return("standard")
    }
  }

  # Sample size based
  if (n_samples < 100) {
    message("Recommendation: 'quick' (small dataset)")
    return("quick")
  }

  # Feature count based
  if (n_features > 1000) {
    message("Recommendation: 'production' (high-dimensional data)")
    return("production")
  }

  # Imbalance based
  if (imbalance_ratio > 5) {
    message("Recommendation: 'robust' (severe imbalance)")
    return("robust")
  }

  # Default
  message("Recommendation: 'standard' (general purpose)")
  return("standard")
}

#' Helper function for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a

################################################################################
# UI HELPERS
################################################################################

#' Create preset selector for Shiny UI
#'
#' @return List of preset options for selectInput
get_preset_choices <- function() {

  presets <- get_all_presets()

  choices <- lapply(names(presets), function(name) {
    paste0(presets[[name]]$name, " (", presets[[name]]$time_estimate, ")")
  })

  names(choices) <- names(presets)

  return(choices)
}

#' Get preset description for UI display
#'
#' @param preset_name Preset name
#' @return HTML formatted description
get_preset_description <- function(preset_name) {

  preset <- get_preset(preset_name)

  description <- paste0(
    "<h4>", preset$name, "</h4>",
    "<p><strong>Time:</strong> ", preset$time_estimate, "</p>",
    "<p><strong>Use Case:</strong> ", preset$use_case, "</p>",
    "<p><strong>Models:</strong> ", paste(preset$models, collapse = ", "), "</p>",
    "<p><strong>Validation:</strong> ", preset$validation$method, "</p>"
  )

  return(description)
}

################################################################################
# EXPORT
################################################################################

message("✓ Preset configurations module loaded")
message("  Available presets: Quick, Standard, Robust, Publication, Exploratory, Production")
message("  Use get_preset('name') to load a preset")
message("  Use apply_preset('name') to apply preset to session")
