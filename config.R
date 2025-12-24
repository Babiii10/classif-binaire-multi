##########################
# Configuration File
# Centralized parameters for model training and data processing
##########################

# Default Model Parameters
# Can be overridden by UI inputs
DEFAULT_PARAMS <- list(

  # Random Forest
  randomforest = list(
    ntree = 1000,
    mtry_default = NULL,  # Will be calculated as sqrt(nvariables)
    nodesize_min = 1,
    nodesize_max = 10,
    importance = TRUE,
    keep_forest = TRUE
  ),

  # XGBoost
  xgboost = list(
    nrounds_default = 200,
    nrounds_min = 10,
    nrounds_max = 1000,
    max_depth_default = 6,
    max_depth_min = 1,
    max_depth_max = 20,
    eta_default = 0.3,
    eta_min = 0.01,
    eta_max = 1,
    min_child_weight = 1,
    subsample = 0.8,
    colsample_bytree = 0.8,
    early_stopping_rounds = 10,
    nfold_cv = 5
  ),

  # LightGBM
  lightgbm = list(
    nrounds_default = 100,
    num_leaves_default = 31,
    learning_rate_default = 0.05,
    min_data_in_leaf = 20,
    max_depth_default = -1,
    bagging_fraction = 0.8,
    feature_fraction = 0.8
  ),

  # SVM
  svm = list(
    cost_default = 1,
    cost_min = 0.001,
    cost_max = 100,
    gamma_default = 0.1,
    gamma_min = 0.00001,
    gamma_max = 10,
    kernel_default = "radial",
    kernel_options = c("radial", "linear", "polynomial", "sigmoid")
  ),

  # KNN
  knn = list(
    k_default = 5,
    k_min = 1,
    k_max = 50
  ),

  # Naive Bayes
  naivebayes = list(
    laplace_default = 0,
    laplace_min = 0,
    laplace_max = 5
  ),

  # ElasticNet / Lasso / Ridge
  regularization = list(
    alpha_default = 0.5,
    lambda_default = NULL,  # NULL = automatic CV
    nlambda = 100,
    nfolds_cv = 10,
    alpha_min = 0,
    alpha_max = 1
  ),

  # Clustering + ElasticNet
  clustEnet = list(
    n_clusters_default = 100,
    n_clusters_min = 10,
    n_clusters_max = 500,
    n_bootstrap_default = 500,
    n_bootstrap_min = 100,
    n_bootstrap_max = 2000,
    alpha_enet_default = 0.5,
    min_selection_freq_default = 0.5,
    min_patients_default = 20,
    preprocess_default = TRUE
  ),

  # Feature Selection
  feature_selection = list(
    # For cross-validation feature selection
    cv_folds = 5,
    cv_repeats = 3,
    # Minimum number of features to keep
    min_features = 2,
    # Maximum number of features (NULL = no limit)
    max_features = NULL
  ),

  # Data Validation
  data_validation = list(
    min_patients_per_class = 5,
    min_total_samples = 10,
    max_missing_rate = 0.9  # Maximum 90% missing values
  )
)

# Performance Settings
PERFORMANCE <- list(
  # Parallel processing
  enable_parallel = TRUE,
  n_cores = NULL,  # NULL = detectCores() - 1
  parallel_backend = "doParallel",  # or "doMC" on Unix

  # Caching
  enable_cache = TRUE,
  cache_dir = ".cache",
  cache_max_age_hours = 24,

  # Progress bars
  show_progress = TRUE,
  progress_style = "shiny"  # or "text" for console
)

# Ensembling Settings
ENSEMBLE <- list(
  # Enable ensemble methods
  enable_ensembling = TRUE,

  # Combination methods
  combination_methods = c("voting", "averaging", "stacking"),
  default_combination = "averaging",

  # Stacking meta-learner
  meta_learner = "glmnet",  # or "randomforest", "xgboost"

  # Minimum models required for ensemble
  min_models_for_ensemble = 3,

  # Weight optimization
  optimize_weights = TRUE,
  weight_optimization_metric = "auc"  # or "accuracy", "f1"
)

# UI/UX Settings
UI_CONFIG <- list(
  # Tooltips
  enable_tooltips = TRUE,
  tooltip_delay = 500,  # milliseconds
  tooltip_placement = "right",

  # Help text
  show_help_default = FALSE,
  help_style = "contextual",  # or "panel", "modal"

  # Color scheme
  color_positive_class = "#F8766D",
  color_negative_class = "#00BFC4",
  color_correct_prediction = "#00BA38",
  color_incorrect_prediction = "#F8766D",

  # Plot defaults
  plot_width = 800,
  plot_height = 600,
  plot_dpi = 100,

  # Download formats
  download_formats_plot = c("png", "jpg", "pdf", "svg"),
  download_formats_table = c("csv", "xlsx", "tsv", "rds")
)

# Grid Search Configuration
GRID_SEARCH <- list(
  # Enable advanced grid search
  enable_advanced_grid = TRUE,

  # Grid search method
  default_method = "random",  # or "grid", "bayesian"

  # Number of iterations for random/bayesian search
  n_iterations = 50,

  # Early stopping
  early_stopping = TRUE,
  early_stopping_patience = 10,

  # Scoring metric for optimization
  scoring_metric = "auc"  # or "accuracy", "f1", "balanced_accuracy"
)

# Logging Configuration
LOGGING <- list(
  enable_logging = TRUE,
  log_level = "INFO",  # DEBUG, INFO, WARNING, ERROR
  log_file = "app.log",
  log_to_console = TRUE
)

##########################
# Helper Functions
##########################

# Get parameter value with fallback to default
get_param <- function(category, param_name, user_value = NULL) {
  if (!is.null(user_value)) {
    return(user_value)
  }

  if (category %in% names(DEFAULT_PARAMS)) {
    if (param_name %in% names(DEFAULT_PARAMS[[category]])) {
      return(DEFAULT_PARAMS[[category]][[param_name]])
    }
  }

  warning(paste("Parameter", param_name, "not found in category", category))
  return(NULL)
}

# Validate parameter value against constraints
validate_param <- function(category, param_name, value) {
  config <- DEFAULT_PARAMS[[category]]

  # Check min/max constraints
  min_name <- paste0(param_name, "_min")
  max_name <- paste0(param_name, "_max")

  if (min_name %in% names(config)) {
    if (value < config[[min_name]]) {
      warning(paste(param_name, "is below minimum:", config[[min_name]]))
      return(config[[min_name]])
    }
  }

  if (max_name %in% names(config)) {
    if (value > config[[max_name]]) {
      warning(paste(param_name, "is above maximum:", config[[max_name]]))
      return(config[[max_name]])
    }
  }

  return(value)
}

# Get default parameters for a model
get_model_defaults <- function(model_type) {
  if (model_type %in% names(DEFAULT_PARAMS)) {
    return(DEFAULT_PARAMS[[model_type]])
  }
  return(list())
}

# Export configuration as JSON
export_config_json <- function(filepath = "config.json") {
  config_list <- list(
    default_params = DEFAULT_PARAMS,
    performance = PERFORMANCE,
    ensemble = ENSEMBLE,
    ui_config = UI_CONFIG,
    grid_search = GRID_SEARCH
  )

  jsonlite::write_json(config_list, filepath, pretty = TRUE, auto_unbox = TRUE)
  message(paste("Configuration exported to:", filepath))
}

# Import configuration from JSON
import_config_json <- function(filepath = "config.json") {
  if (!file.exists(filepath)) {
    warning(paste("Config file not found:", filepath))
    return(FALSE)
  }

  tryCatch({
    config <- jsonlite::read_json(filepath, simplifyVector = TRUE)

    if ("default_params" %in% names(config)) {
      DEFAULT_PARAMS <<- config$default_params
    }
    if ("performance" %in% names(config)) {
      PERFORMANCE <<- config$performance
    }
    if ("ensemble" %in% names(config)) {
      ENSEMBLE <<- config$ensemble
    }
    if ("ui_config" %in% names(config)) {
      UI_CONFIG <<- config$ui_config
    }
    if ("grid_search" %in% names(config)) {
      GRID_SEARCH <<- config$grid_search
    }

    message(paste("Configuration imported from:", filepath))
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error importing config:", e$message))
    return(FALSE)
  })
}

# Print current configuration
print_config <- function() {
  cat("===== Current Configuration =====\n")
  cat("\n--- Default Parameters ---\n")
  print(DEFAULT_PARAMS)
  cat("\n--- Performance Settings ---\n")
  print(PERFORMANCE)
  cat("\n--- Ensemble Settings ---\n")
  print(ENSEMBLE)
  cat("\n--- UI Configuration ---\n")
  print(UI_CONFIG)
  cat("\n--- Grid Search Configuration ---\n")
  print(GRID_SEARCH)
  cat("\n================================\n")
}

##########################
# Initialize configuration
##########################

# Try to load custom config if exists
if (file.exists("custom_config.json")) {
  import_config_json("custom_config.json")
  message("Loaded custom configuration")
} else {
  message("Using default configuration")
}
