##########################
# AutoML System
# Automatic model selection and hyperparameter optimization
##########################

##########################
# Main AutoML Function
##########################

auto_ml <- function(data, time_budget_minutes = 30, metric = "auc",
                   models_to_try = c("randomforest", "xgboost", "svm", "elasticnet"),
                   ensemble = TRUE, verbose = TRUE) {

  start_time <- Sys.time()

  if(verbose) {
    cat("===== AutoML Started =====\n")
    cat(sprintf("Time budget: %d minutes\n", time_budget_minutes))
    cat(sprintf("Metric: %s\n", metric))
    cat(sprintf("Models to try: %s\n", paste(models_to_try, collapse = ", ")))
    cat("\n")
  }

  results <- list()

  ##########################
  # Phase 1: Quick Screening
  ##########################

  if(verbose) cat("📊 Phase 1: Quick screening of all models...\n")

  quick_results <- quick_model_screening(
    data = data,
    models = models_to_try,
    metric = metric,
    cv_folds = 3,
    verbose = verbose
  )

  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
  if(verbose) cat(sprintf("   Completed in %.1f minutes\n\n", elapsed))

  ##########################
  # Phase 2: Select Top Models
  ##########################

  # Budget for phase 2
  remaining_budget <- time_budget_minutes - elapsed

  if(remaining_budget < 5) {
    if(verbose) cat("⏱️  Time budget exhausted. Returning quick screening results.\n")
    return(list(
      best_model = quick_results$models[[1]],
      best_model_type = quick_results$rankings[1, "model"],
      best_score = quick_results$rankings[1, "mean_score"],
      all_results = quick_results$rankings,
      ensemble = NULL
    ))
  }

  # Select top 3 models for detailed tuning
  top_n <- min(3, nrow(quick_results$rankings))
  top_models <- quick_results$rankings$model[1:top_n]

  if(verbose) {
    cat(sprintf("🎯 Phase 2: Detailed tuning of top %d models...\n", top_n))
    cat(sprintf("   Selected: %s\n", paste(top_models, collapse = ", ")))
  }

  ##########################
  # Phase 3: Hyperparameter Tuning
  ##########################

  tuned_results <- list()
  time_per_model <- remaining_budget / top_n

  for(i in 1:top_n) {
    if(difftime(Sys.time(), start_time, units = "mins") > time_budget_minutes) {
      if(verbose) cat("   ⏱️ Time budget reached\n")
      break
    }

    model_type <- top_models[i]

    if(verbose) cat(sprintf("\n   Tuning %s (budget: %.1f min)...\n", model_type, time_per_model))

    tuned_results[[i]] <- tune_model_hyperparameters(
      data = data,
      model_type = model_type,
      metric = metric,
      time_budget_minutes = time_per_model,
      verbose = verbose
    )

    tuned_results[[i]]$model_type <- model_type
  }

  ##########################
  # Phase 4: Ensemble (if enabled and time permits)
  ##########################

  ensemble_model <- NULL

  if(ensemble && length(tuned_results) >= 2) {
    remaining_time <- time_budget_minutes - as.numeric(difftime(Sys.time(), start_time, units = "mins"))

    if(remaining_time > 2) {
      if(verbose) cat("\n🤝 Phase 4: Creating ensemble...\n")

      ensemble_model <- tryCatch({
        create_ensemble(
          models = lapply(tuned_results, function(x) x$model),
          model_types = sapply(tuned_results, function(x) x$model_type),
          combination_method = "averaging",  # Fast method
          training_data = data
        )
      }, error = function(e) {
        if(verbose) cat(sprintf("   ⚠️  Ensemble creation failed: %s\n", e$message))
        NULL
      })
    } else {
      if(verbose) cat("\n⏱️  Insufficient time for ensemble creation\n")
    }
  }

  ##########################
  # Final Results
  ##########################

  # Find best individual model
  best_idx <- which.max(sapply(tuned_results, function(x) x$best_score))
  best_model <- tuned_results[[best_idx]]

  total_time <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))

  if(verbose) {
    cat("\n===== AutoML Completed =====\n")
    cat(sprintf("Total time: %.1f minutes\n", total_time))
    cat(sprintf("Best model: %s\n", best_model$model_type))
    cat(sprintf("Best %s: %.4f\n", metric, best_model$best_score))
    if(!is.null(ensemble_model)) {
      cat("✅ Ensemble model created\n")
    }
    cat("============================\n\n")
  }

  return(list(
    best_model = best_model$model,
    best_model_type = best_model$model_type,
    best_score = best_model$best_score,
    best_params = best_model$best_params,
    all_models = tuned_results,
    ensemble = ensemble_model,
    quick_screening_results = quick_results$rankings,
    total_time_minutes = total_time
  ))
}

##########################
# Quick Model Screening
##########################

quick_model_screening <- function(data, models, metric = "auc",
                                  cv_folds = 3, verbose = TRUE) {

  n_models <- length(models)
  results <- data.frame(
    model = character(n_models),
    mean_score = numeric(n_models),
    sd_score = numeric(n_models),
    time_seconds = numeric(n_models),
    stringsAsFactors = FALSE
  )

  trained_models <- list()

  for(i in 1:n_models) {
    model_type <- models[i]

    if(verbose) cat(sprintf("   Testing %s...", model_type))

    start <- Sys.time()

    # Get default parameters
    params <- get_default_model_params(model_type)

    # Quick cross-validation
    cv_result <- tryCatch({
      quick_cross_validate(data, model_type, params, cv_folds, metric)
    }, error = function(e) {
      if(verbose) cat(sprintf(" FAILED (%s)\n", e$message))
      list(mean_score = 0, sd_score = 0, model = NULL)
    })

    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

    results[i,] <- data.frame(
      model = model_type,
      mean_score = cv_result$mean_score,
      sd_score = cv_result$sd_score,
      time_seconds = elapsed
    )

    trained_models[[i]] <- cv_result$model

    if(verbose) {
      cat(sprintf(" %s = %.4f (±%.4f) [%.1fs]\n",
                  metric, cv_result$mean_score, cv_result$sd_score, elapsed))
    }
  }

  # Rank by score
  rankings <- results[order(-results$mean_score), ]
  rownames(rankings) <- NULL

  list(
    rankings = rankings,
    models = trained_models[order(-results$mean_score)]
  )
}

##########################
# Hyperparameter Tuning
##########################

tune_model_hyperparameters <- function(data, model_type, metric = "auc",
                                      time_budget_minutes = 10,
                                      method = "random", n_iter = 20,
                                      verbose = TRUE) {

  start_time <- Sys.time()

  # Get parameter grid
  param_grid <- get_param_grid(model_type)

  if(method == "random") {
    # Random search
    results <- random_search_cv(
      data = data,
      model_type = model_type,
      param_grid = param_grid,
      metric = metric,
      n_iter = n_iter,
      time_budget_minutes = time_budget_minutes,
      verbose = verbose
    )
  } else if(method == "grid") {
    # Grid search
    results <- grid_search_cv(
      data = data,
      model_type = model_type,
      param_grid = param_grid,
      metric = metric,
      time_budget_minutes = time_budget_minutes,
      verbose = verbose
    )
  } else {
    stop("Unknown tuning method. Use 'random' or 'grid'")
  }

  return(results)
}

##########################
# Random Search
##########################

random_search_cv <- function(data, model_type, param_grid, metric,
                            n_iter = 20, time_budget_minutes = 10,
                            cv_folds = 5, verbose = TRUE) {

  start_time <- Sys.time()
  best_score <- -Inf
  best_params <- NULL
  best_model <- NULL

  all_results <- data.frame()

  for(iter in 1:n_iter) {
    # Check time budget
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
    if(elapsed > time_budget_minutes) {
      if(verbose) cat(sprintf("      Iteration %d/%d - Time budget reached\n", iter, n_iter))
      break
    }

    # Sample random parameters
    params <- sample_params_from_grid(param_grid)

    # Cross-validate
    cv_result <- tryCatch({
      quick_cross_validate(data, model_type, params, cv_folds, metric)
    }, error = function(e) {
      list(mean_score = 0, sd_score = 0, model = NULL)
    })

    # Record results
    all_results <- rbind(all_results, data.frame(
      iteration = iter,
      params = I(list(params)),
      mean_score = cv_result$mean_score,
      sd_score = cv_result$sd_score
    ))

    # Update best
    if(cv_result$mean_score > best_score) {
      best_score <- cv_result$mean_score
      best_params <- params
      best_model <- cv_result$model

      if(verbose) {
        cat(sprintf("      ✓ Iteration %d/%d - New best %s: %.4f\n",
                    iter, n_iter, metric, best_score))
      }
    } else {
      if(verbose && iter %% 5 == 0) {
        cat(sprintf("      Iteration %d/%d - Current best: %.4f\n",
                    iter, n_iter, best_score))
      }
    }
  }

  # Train final model with best params
  if(is.null(best_model)) {
    best_model <- train_model_with_params(data, model_type, best_params)
  }

  list(
    best_score = best_score,
    best_params = best_params,
    model = best_model,
    all_results = all_results
  )
}

##########################
# Helper Functions
##########################

get_default_model_params <- function(model_type) {
  switch(model_type,
    "randomforest" = list(
      ntree = 500,
      mtry = NULL  # Will be set to sqrt(n_features)
    ),
    "xgboost" = list(
      nrounds = 100,
      max_depth = 6,
      eta = 0.3,
      min_child_weight = 1
    ),
    "svm" = list(
      kernel = "radial",
      cost = 1,
      gamma = 0.1
    ),
    "elasticnet" = list(
      alpha = 0.5,
      lambda = NULL  # Will be determined by CV
    ),
    "knn" = list(
      k = 5
    ),
    "naivebayes" = list(
      laplace = 0
    ),
    list()
  )
}

get_param_grid <- function(model_type) {
  switch(model_type,
    "randomforest" = list(
      ntree = c(300, 500, 1000),
      mtry = c("sqrt", "log2", "third")
    ),
    "xgboost" = list(
      nrounds = c(50, 100, 200, 500),
      max_depth = c(3, 6, 9, 12),
      eta = c(0.01, 0.05, 0.1, 0.3),
      min_child_weight = c(1, 3, 5)
    ),
    "svm" = list(
      kernel = c("radial", "linear"),
      cost = c(0.1, 1, 10, 100),
      gamma = c(0.001, 0.01, 0.1, 1)
    ),
    "elasticnet" = list(
      alpha = seq(0, 1, 0.1)
    ),
    "knn" = list(
      k = c(3, 5, 7, 9, 11, 15, 21)
    ),
    "naivebayes" = list(
      laplace = c(0, 0.5, 1, 2)
    ),
    list()
  )
}

sample_params_from_grid <- function(param_grid) {
  params <- list()
  for(param_name in names(param_grid)) {
    param_values <- param_grid[[param_name]]
    params[[param_name]] <- sample(param_values, 1)
  }
  return(params)
}

quick_cross_validate <- function(data, model_type, params, cv_folds, metric) {
  n_samples <- nrow(data)

  # Create folds
  set.seed(42)
  fold_indices <- sample(rep(1:cv_folds, length.out = n_samples))

  scores <- numeric(cv_folds)

  for(fold in 1:cv_folds) {
    test_idx <- which(fold_indices == fold)
    train_idx <- which(fold_indices != fold)

    train_data <- data[train_idx, ]
    test_data <- data[test_idx, ]

    # Train model
    model <- train_model_with_params(train_data, model_type, params)

    # Predict and evaluate
    n_classes <- length(levels(data[,1]))
    predictions <- predict_model(model, model_type, test_data, n_classes)

    # Calculate metric
    scores[fold] <- calculate_metric(test_data[,1], predictions$scores, metric)
  }

  # Train final model on full data
  final_model <- train_model_with_params(data, model_type, params)

  list(
    mean_score = mean(scores, na.rm = TRUE),
    sd_score = sd(scores, na.rm = TRUE),
    model = final_model
  )
}

train_model_with_params <- function(data, model_type, params) {
  # This would call the actual model training functions
  # For now, placeholder
  NULL
}

predict_model <- function(model, model_type, data, n_classes) {
  # Placeholder for prediction
  list(scores = runif(nrow(data)))
}

##########################
# Model Recommendation
##########################

recommend_best_model <- function(data, task_type = "auto") {

  n_samples <- nrow(data)
  n_features <- ncol(data) - 1
  n_classes <- length(levels(data[,1]))

  recommendations <- list()

  # Based on sample size
  if(n_samples < 100) {
    recommendations$size <- c("knn", "naivebayes", "svm")
  } else if(n_samples < 1000) {
    recommendations$size <- c("randomforest", "xgboost", "svm")
  } else {
    recommendations$size <- c("xgboost", "randomforest", "lightgbm")
  }

  # Based on feature/sample ratio
  ratio <- n_samples / n_features
  if(ratio < 5) {
    recommendations$ratio <- c("elasticnet", "ridge", "lasso")
  } else if(ratio < 20) {
    recommendations$ratio <- c("randomforest", "elasticnet", "svm")
  } else {
    recommendations$ratio <- c("randomforest", "xgboost", "svm")
  }

  # Based on number of classes
  if(n_classes == 2) {
    recommendations$classes <- c("svm", "xgboost", "randomforest")
  } else {
    recommendations$classes <- c("randomforest", "xgboost", "elasticnet")
  }

  # Aggregate recommendations
  all_models <- unlist(recommendations)
  model_counts <- table(all_models)
  top_models <- names(sort(model_counts, decreasing = TRUE))

  list(
    recommended_models = head(top_models, 3),
    reasoning = list(
      n_samples = n_samples,
      n_features = n_features,
      n_classes = n_classes,
      ratio = ratio
    )
  )
}

message("AutoML system loaded")
