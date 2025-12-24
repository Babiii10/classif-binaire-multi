##########################
# Parallel Computing System
# Speed up computations using multiple CPU cores
##########################

# Load required packages
if (!require("doParallel")) {
  install.packages("doParallel")
  library(doParallel)
}

if (!require("foreach")) {
  install.packages("foreach")
  library(foreach)
}

##########################
# Parallel Backend Setup
##########################

# Initialize parallel backend
init_parallel <- function(n_cores = NULL) {
  if (!PERFORMANCE$enable_parallel) {
    message("Parallel processing is disabled")
    return(FALSE)
  }

  # Determine number of cores
  if (is.null(n_cores)) {
    n_cores <- PERFORMANCE$n_cores
  }

  if (is.null(n_cores)) {
    total_cores <- parallel::detectCores()
    n_cores <- max(1, total_cores - 1)  # Leave one core free
  }

  # Setup parallel backend
  tryCatch({
    cl <- parallel::makeCluster(n_cores)
    doParallel::registerDoParallel(cl)

    message(paste("Parallel backend initialized with", n_cores, "cores"))

    # Store cluster object for cleanup
    assign("parallel_cluster", cl, envir = .GlobalEnv)

    return(TRUE)
  }, error = function(e) {
    warning(paste("Failed to initialize parallel backend:", e$message))
    return(FALSE)
  })
}

# Stop parallel backend
stop_parallel <- function() {
  if (exists("parallel_cluster", envir = .GlobalEnv)) {
    cl <- get("parallel_cluster", envir = .GlobalEnv)
    parallel::stopCluster(cl)
    rm(parallel_cluster, envir = .GlobalEnv)
    message("Parallel backend stopped")
  }
}

# Check if parallel backend is active
is_parallel_active <- function() {
  foreach::getDoParRegistered()
}

##########################
# Parallel Model Training
##########################

# Train multiple models in parallel
train_models_parallel <- function(data, model_types, parameters_list,
                                   progress_callback = NULL) {
  if (!is_parallel_active()) {
    init_parallel()
  }

  n_models <- length(model_types)

  message(paste("Training", n_models, "models in parallel..."))

  results <- foreach(i = 1:n_models,
                     .packages = c("randomForest", "e1071", "glmnet", "xgboost",
                                   "class", "naivebayes"),
                     .export = ls(envir = .GlobalEnv)) %dopar% {

    model_type <- model_types[i]
    params <- parameters_list[[i]]

    # Progress update
    if (!is.null(progress_callback)) {
      progress_callback(i, n_models)
    }

    # Train model
    tryCatch({
      model <- train_single_model(data, model_type, params)
      list(success = TRUE, model = model, model_type = model_type, error = NULL)
    }, error = function(e) {
      list(success = FALSE, model = NULL, model_type = model_type, error = e$message)
    })
  }

  # Extract successful models
  successful_models <- lapply(results[sapply(results, function(x) x$success)],
                              function(x) x$model)
  failed_models <- lapply(results[!sapply(results, function(x) x$success)],
                          function(x) list(type = x$model_type, error = x$error))

  if (length(failed_models) > 0) {
    warning(paste(length(failed_models), "models failed to train"))
    for (fm in failed_models) {
      warning(paste(" -", fm$type, ":", fm$error))
    }
  }

  return(list(
    models = successful_models,
    model_types = sapply(results[sapply(results, function(x) x$success)],
                         function(x) x$model_type),
    failed = failed_models,
    n_successful = length(successful_models),
    n_failed = length(failed_models)
  ))
}

# Train single model (helper function)
train_single_model <- function(data, model_type, params) {
  switch(model_type,
         "randomforest" = train_rf_model(data, params),
         "svm" = train_svm_model(data, params),
         "elasticnet" = train_elasticnet_model(data, params),
         "xgboost" = train_xgb_model(data, params),
         "knn" = train_knn_model(data, params),
         "naivebayes" = train_nb_model(data, params),
         stop("Unknown model type"))
}

##########################
# Parallel Parameter Grid Search
##########################

# Perform grid search in parallel
parallel_grid_search <- function(data, model_type, param_grid,
                                  cv_folds = 5, metric = "auc") {
  if (!is_parallel_active()) {
    init_parallel()
  }

  # Generate all parameter combinations
  param_combinations <- expand.grid(param_grid)
  n_combinations <- nrow(param_combinations)

  message(paste("Testing", n_combinations, "parameter combinations in parallel..."))

  # Parallel grid search
  results <- foreach(i = 1:n_combinations,
                     .packages = c("randomForest", "e1071", "glmnet", "xgboost",
                                   "class", "naivebayes", "pROC"),
                     .combine = rbind,
                     .export = ls(envir = .GlobalEnv)) %dopar% {

    params <- as.list(param_combinations[i, ])

    # Perform cross-validation
    cv_result <- cross_validate_params(data, model_type, params, cv_folds, metric)

    data.frame(
      param_combination = i,
      mean_score = cv_result$mean_score,
      sd_score = cv_result$sd_score,
      params = I(list(params))
    )
  }

  # Find best parameters
  best_idx <- which.max(results$mean_score)
  best_params <- results$params[[best_idx]]
  best_score <- results$mean_score[best_idx]

  return(list(
    best_params = best_params,
    best_score = best_score,
    all_results = results,
    n_tested = n_combinations
  ))
}

# Cross-validate with specific parameters
cross_validate_params <- function(data, model_type, params, cv_folds, metric) {
  n_samples <- nrow(data)
  folds <- createFolds(data[,1], k = cv_folds, list = TRUE)

  scores <- numeric(cv_folds)

  for (fold_idx in 1:cv_folds) {
    test_idx <- folds[[fold_idx]]
    train_idx <- setdiff(1:n_samples, test_idx)

    train_data <- data[train_idx, ]
    test_data <- data[test_idx, ]

    # Train model
    model <- train_single_model(train_data, model_type, params)

    # Evaluate
    n_classes <- get_n_classes(data[,1])
    pred_result <- get_model_predictions(model, model_type, test_data, n_classes)

    scores[fold_idx] <- calculate_metric(test_data[,1], pred_result$scores, metric)
  }

  return(list(
    mean_score = mean(scores),
    sd_score = sd(scores),
    all_scores = scores
  ))
}

##########################
# Parallel Feature Selection
##########################

# Perform feature selection in parallel
parallel_feature_selection <- function(data, method = "importance",
                                       n_top_features = 50) {
  if (!is_parallel_active()) {
    init_parallel()
  }

  n_features <- ncol(data) - 1

  message(paste("Evaluating", n_features, "features in parallel..."))

  # Calculate feature importance scores in parallel
  feature_scores <- foreach(i = 2:ncol(data),
                            .packages = c("pROC"),
                            .combine = c) %dopar% {

    feature_data <- data[, c(1, i)]

    if (method == "auc") {
      # Calculate AUC for each feature
      roc_obj <- roc(data[,1], data[,i], quiet = TRUE)
      return(as.numeric(auc(roc_obj)))
    } else if (method == "correlation") {
      # Calculate correlation with target
      cor_val <- abs(cor(as.numeric(data[,1]), data[,i], use = "complete.obs"))
      return(cor_val)
    } else if (method == "wilcoxon") {
      # Wilcoxon test p-value
      test_result <- wilcox.test(data[,i] ~ data[,1])
      return(-log10(test_result$p.value))  # Higher is better
    }
  }

  # Rank features
  feature_names <- colnames(data)[-1]
  ranked_features <- data.frame(
    feature = feature_names,
    score = feature_scores,
    rank = rank(-feature_scores)
  )

  ranked_features <- ranked_features[order(-ranked_features$score), ]

  # Select top features
  top_features <- ranked_features$feature[1:min(n_top_features, nrow(ranked_features))]

  return(list(
    top_features = top_features,
    all_rankings = ranked_features,
    n_selected = length(top_features)
  ))
}

##########################
# Parallel Cross-Validation
##########################

# Perform k-fold cross-validation in parallel
parallel_cross_validation <- function(data, model_type, params,
                                       k_folds = 10, repeats = 1) {
  if (!is_parallel_active()) {
    init_parallel()
  }

  n_total <- k_folds * repeats

  message(paste("Running", n_total, "CV iterations in parallel..."))

  # Parallel CV
  cv_results <- foreach(rep = 1:repeats,
                        .packages = c("randomForest", "e1071", "glmnet", "xgboost",
                                      "class", "naivebayes", "pROC", "caret"),
                        .combine = rbind) %:%
    foreach(fold = 1:k_folds,
            .combine = rbind) %dopar% {

      # Create folds
      set.seed(rep * 1000 + fold)
      folds <- createFolds(data[,1], k = k_folds, list = TRUE)

      test_idx <- folds[[fold]]
      train_idx <- setdiff(1:nrow(data), test_idx)

      train_data <- data[train_idx, ]
      test_data <- data[test_idx, ]

      # Train model
      model <- train_single_model(train_data, model_type, params)

      # Evaluate
      n_classes <- get_n_classes(data[,1])
      pred_result <- get_model_predictions(model, model_type, test_data, n_classes)

      # Calculate metrics
      metrics <- calculate_all_metrics(test_data[,1], pred_result$scores,
                                       pred_result$predictions)

      data.frame(
        repeat_id = rep,
        fold_id = fold,
        auc = metrics$auc,
        accuracy = metrics$accuracy,
        sensitivity = metrics$sensitivity,
        specificity = metrics$specificity
      )
    }

  # Aggregate results
  summary_stats <- list(
    mean_auc = mean(cv_results$auc),
    sd_auc = sd(cv_results$auc),
    mean_accuracy = mean(cv_results$accuracy),
    sd_accuracy = sd(cv_results$accuracy),
    mean_sensitivity = mean(cv_results$sensitivity),
    sd_sensitivity = sd(cv_results$sensitivity),
    mean_specificity = mean(cv_results$specificity),
    sd_specificity = sd(cv_results$specificity),
    all_results = cv_results
  )

  return(summary_stats)
}

##########################
# Parallel Bootstrap
##########################

# Perform bootstrap validation in parallel
parallel_bootstrap <- function(data, model_type, params, n_bootstrap = 1000) {
  if (!is_parallel_active()) {
    init_parallel()
  }

  message(paste("Running", n_bootstrap, "bootstrap iterations in parallel..."))

  # Parallel bootstrap
  bootstrap_results <- foreach(i = 1:n_bootstrap,
                               .packages = c("randomForest", "e1071", "glmnet",
                                             "xgboost", "class", "naivebayes", "pROC"),
                               .combine = rbind) %dopar% {

    # Bootstrap sample
    set.seed(i)
    boot_idx <- sample(1:nrow(data), replace = TRUE)
    oob_idx <- setdiff(1:nrow(data), unique(boot_idx))

    if (length(oob_idx) == 0) {
      return(NULL)
    }

    train_data <- data[boot_idx, ]
    test_data <- data[oob_idx, ]

    # Train model
    model <- train_single_model(train_data, model_type, params)

    # Evaluate on OOB samples
    n_classes <- get_n_classes(data[,1])
    pred_result <- get_model_predictions(model, model_type, test_data, n_classes)

    # Calculate metrics
    metrics <- calculate_all_metrics(test_data[,1], pred_result$scores,
                                     pred_result$predictions)

    data.frame(
      iteration = i,
      auc = metrics$auc,
      accuracy = metrics$accuracy,
      sensitivity = metrics$sensitivity,
      specificity = metrics$specificity
    )
  }

  # Remove NULL results
  bootstrap_results <- bootstrap_results[!is.null(bootstrap_results), ]

  # Aggregate results with confidence intervals
  summary_stats <- list(
    mean_auc = mean(bootstrap_results$auc, na.rm = TRUE),
    ci_auc = quantile(bootstrap_results$auc, c(0.025, 0.975), na.rm = TRUE),
    mean_accuracy = mean(bootstrap_results$accuracy, na.rm = TRUE),
    ci_accuracy = quantile(bootstrap_results$accuracy, c(0.025, 0.975), na.rm = TRUE),
    all_results = bootstrap_results,
    n_iterations = nrow(bootstrap_results)
  )

  return(summary_stats)
}

##########################
# Parallel Test All Models
##########################

# Test all model/parameter combinations in parallel
parallel_test_all_models <- function(data, model_types, parameter_grid_list,
                                      cv_folds = 5, metric = "auc",
                                      progress = NULL) {
  if (!is_parallel_active()) {
    init_parallel()
  }

  # Create all combinations
  all_combinations <- list()
  combination_id <- 1

  for (i in seq_along(model_types)) {
    model_type <- model_types[i]
    param_grid <- parameter_grid_list[[i]]

    param_combinations <- expand.grid(param_grid)

    for (j in 1:nrow(param_combinations)) {
      all_combinations[[combination_id]] <- list(
        model_type = model_type,
        params = as.list(param_combinations[j, ]),
        combination_id = combination_id
      )
      combination_id <- combination_id + 1
    }
  }

  n_total <- length(all_combinations)
  message(paste("Testing", n_total, "model/parameter combinations in parallel..."))

  # Progress tracking for Shiny
  if (!is.null(progress)) {
    progress$set(message = "Testing models in parallel", value = 0)
  }

  # Parallel testing
  results <- foreach(i = 1:n_total,
                     .packages = c("randomForest", "e1071", "glmnet", "xgboost",
                                   "class", "naivebayes", "pROC", "caret"),
                     .combine = rbind) %dopar% {

    combo <- all_combinations[[i]]

    # Update progress
    if (!is.null(progress)) {
      progress$inc(1/n_total, detail = paste("Model", i, "of", n_total))
    }

    # Cross-validate
    cv_result <- cross_validate_params(data, combo$model_type, combo$params,
                                       cv_folds, metric)

    data.frame(
      combination_id = combo$combination_id,
      model_type = combo$model_type,
      mean_score = cv_result$mean_score,
      sd_score = cv_result$sd_score,
      params = I(list(combo$params))
    )
  }

  return(results)
}

##########################
# Helper Functions
##########################

# Calculate all metrics
calculate_all_metrics <- function(true_labels, predicted_scores, predicted_classes) {
  n_classes <- length(levels(true_labels))

  auc <- tryCatch(
    calculate_multiclass_auc(true_labels, predicted_scores),
    error = function(e) NA
  )

  accuracy <- mean(predicted_classes == true_labels)

  if (n_classes == 2) {
    cm <- table(Predicted = predicted_classes, Actual = true_labels)
    sensitivity <- cm[2,2] / sum(cm[,2])
    specificity <- cm[1,1] / sum(cm[,1])
  } else {
    # Multi-class: average sensitivity/specificity
    cm <- table(Predicted = predicted_classes, Actual = true_labels)
    sensitivity <- mean(diag(cm) / colSums(cm))
    specificity <- mean(diag(cm) / colSums(cm))
  }

  list(
    auc = auc,
    accuracy = accuracy,
    sensitivity = sensitivity,
    specificity = specificity
  )
}

# Create folds (if caret not available)
createFolds <- function(y, k = 10, list = TRUE) {
  if (requireNamespace("caret", quietly = TRUE)) {
    return(caret::createFolds(y, k = k, list = list))
  }

  # Simple implementation
  n <- length(y)
  indices <- sample(1:n)
  folds <- split(indices, cut(1:n, breaks = k, labels = FALSE))

  if (list) {
    return(folds)
  } else {
    fold_vector <- numeric(n)
    for (i in seq_along(folds)) {
      fold_vector[folds[[i]]] <- i
    }
    return(fold_vector)
  }
}

##########################
# Cleanup on unload
##########################

# Register cleanup function
reg.finalizer(.GlobalEnv, function(e) {
  stop_parallel()
}, onexit = TRUE)

message("Parallel computing system initialized")
