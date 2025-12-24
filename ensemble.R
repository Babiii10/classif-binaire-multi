##########################
# Ensemble Methods
# Combine multiple models for improved prediction performance
##########################

##########################
# Ensemble Creation
##########################

# Create ensemble from multiple trained models
create_ensemble <- function(models, model_types, combination_method = "averaging",
                            meta_learner = NULL, training_data = NULL) {
  if (!ENSEMBLE$enable_ensembling) {
    warning("Ensembling is disabled in configuration")
    return(NULL)
  }

  if (length(models) < ENSEMBLE$min_models_for_ensemble) {
    warning(paste("Need at least", ENSEMBLE$min_models_for_ensemble, "models for ensemble"))
    return(NULL)
  }

  ensemble <- list(
    models = models,
    model_types = model_types,
    combination_method = combination_method,
    n_models = length(models),
    weights = NULL,
    meta_learner = NULL,
    created_at = Sys.time()
  )

  # Initialize weights
  if (combination_method %in% c("weighted_averaging", "weighted_voting")) {
    if (ENSEMBLE$optimize_weights && !is.null(training_data)) {
      ensemble$weights <- optimize_ensemble_weights(models, model_types, training_data)
    } else {
      # Equal weights
      ensemble$weights <- rep(1 / length(models), length(models))
    }
  }

  # Train meta-learner for stacking
  if (combination_method == "stacking" && !is.null(training_data)) {
    ensemble$meta_learner <- train_meta_learner(models, model_types, training_data,
                                                meta_learner %||% ENSEMBLE$meta_learner)
  }

  class(ensemble) <- c("ensemble", "list")
  return(ensemble)
}

##########################
# Prediction Methods
##########################

# Make predictions using ensemble
predict_ensemble <- function(ensemble, newdata, threshold = 0.5) {
  if (!inherits(ensemble, "ensemble")) {
    stop("Object is not an ensemble")
  }

  n_classes <- get_n_classes(newdata[,1])
  combination_method <- ensemble$combination_method

  # Get predictions from all models
  all_predictions <- list()
  all_scores <- list()

  for (i in seq_along(ensemble$models)) {
    model <- ensemble$models[[i]]
    model_type <- ensemble$model_types[i]

    # Get predictions based on model type
    pred_result <- get_model_predictions(model, model_type, newdata, n_classes)

    all_predictions[[i]] <- pred_result$predictions
    all_scores[[i]] <- pred_result$scores
  }

  # Combine predictions
  final_result <- switch(combination_method,
                         "voting" = ensemble_voting(all_predictions, n_classes),
                         "averaging" = ensemble_averaging(all_scores, n_classes, threshold),
                         "weighted_averaging" = ensemble_weighted_averaging(all_scores, ensemble$weights,
                                                                            n_classes, threshold),
                         "weighted_voting" = ensemble_weighted_voting(all_predictions, ensemble$weights,
                                                                      n_classes),
                         "stacking" = ensemble_stacking(all_scores, ensemble$meta_learner,
                                                       n_classes, threshold),
                         stop("Unknown combination method"))

  return(final_result)
}

##########################
# Combination Methods
##########################

# Simple majority voting
ensemble_voting <- function(predictions_list, n_classes) {
  n_samples <- length(predictions_list[[1]])
  votes <- matrix(0, nrow = n_samples, ncol = n_classes)

  for (preds in predictions_list) {
    for (i in seq_len(n_samples)) {
      class_idx <- as.numeric(preds[i])
      votes[i, class_idx] <- votes[i, class_idx] + 1
    }
  }

  # Get class with most votes
  final_predictions <- apply(votes, 1, which.max)
  final_predictions <- factor(final_predictions, levels = 1:n_classes)

  list(
    predictions = final_predictions,
    scores = votes / length(predictions_list)  # Normalized vote counts
  )
}

# Weighted voting
ensemble_weighted_voting <- function(predictions_list, weights, n_classes) {
  n_samples <- length(predictions_list[[1]])
  votes <- matrix(0, nrow = n_samples, ncol = n_classes)

  for (j in seq_along(predictions_list)) {
    preds <- predictions_list[[j]]
    w <- weights[j]

    for (i in seq_len(n_samples)) {
      class_idx <- as.numeric(preds[i])
      votes[i, class_idx] <- votes[i, class_idx] + w
    }
  }

  # Get class with highest weighted votes
  final_predictions <- apply(votes, 1, which.max)
  final_predictions <- factor(final_predictions, levels = 1:n_classes)

  list(
    predictions = final_predictions,
    scores = votes / sum(weights)  # Normalized weighted votes
  )
}

# Average probabilities
ensemble_averaging <- function(scores_list, n_classes, threshold = 0.5) {
  if (n_classes == 2) {
    # Binary: scores are vectors
    avg_scores <- Reduce("+", scores_list) / length(scores_list)
    final_predictions <- ifelse(avg_scores > threshold, 2, 1)
    final_predictions <- factor(final_predictions, levels = 1:2)

    return(list(
      predictions = final_predictions,
      scores = avg_scores
    ))
  } else {
    # Multi-class: scores are matrices
    avg_scores <- Reduce("+", scores_list) / length(scores_list)
    final_predictions <- apply(avg_scores, 1, which.max)
    final_predictions <- factor(final_predictions, levels = 1:n_classes)

    return(list(
      predictions = final_predictions,
      scores = avg_scores
    ))
  }
}

# Weighted average of probabilities
ensemble_weighted_averaging <- function(scores_list, weights, n_classes, threshold = 0.5) {
  if (n_classes == 2) {
    # Binary: scores are vectors
    weighted_sum <- 0
    for (i in seq_along(scores_list)) {
      weighted_sum <- weighted_sum + scores_list[[i]] * weights[i]
    }
    avg_scores <- weighted_sum / sum(weights)

    final_predictions <- ifelse(avg_scores > threshold, 2, 1)
    final_predictions <- factor(final_predictions, levels = 1:2)

    return(list(
      predictions = final_predictions,
      scores = avg_scores
    ))
  } else {
    # Multi-class: scores are matrices
    weighted_sum <- 0
    for (i in seq_along(scores_list)) {
      weighted_sum <- weighted_sum + scores_list[[i]] * weights[i]
    }
    avg_scores <- weighted_sum / sum(weights)

    final_predictions <- apply(avg_scores, 1, which.max)
    final_predictions <- factor(final_predictions, levels = 1:n_classes)

    return(list(
      predictions = final_predictions,
      scores = avg_scores
    ))
  }
}

# Stacking with meta-learner
ensemble_stacking <- function(scores_list, meta_learner, n_classes, threshold = 0.5) {
  if (is.null(meta_learner)) {
    stop("Meta-learner not trained for stacking")
  }

  # Create meta-features from base model predictions
  if (n_classes == 2) {
    meta_features <- do.call(cbind, scores_list)
  } else {
    # For multi-class, flatten score matrices
    meta_features <- do.call(cbind, lapply(scores_list, as.vector))
  }

  # Predict using meta-learner
  meta_pred <- predict(meta_learner$model, newx = as.matrix(meta_features),
                       s = "lambda.min", type = "response")

  if (n_classes == 2) {
    final_scores <- as.vector(meta_pred)
    final_predictions <- ifelse(final_scores > threshold, 2, 1)
    final_predictions <- factor(final_predictions, levels = 1:2)
  } else {
    final_scores <- matrix(meta_pred, ncol = n_classes)
    final_predictions <- apply(final_scores, 1, which.max)
    final_predictions <- factor(final_predictions, levels = 1:n_classes)
  }

  return(list(
    predictions = final_predictions,
    scores = final_scores
  ))
}

##########################
# Meta-Learner Training
##########################

# Train meta-learner for stacking
train_meta_learner <- function(models, model_types, training_data, meta_type = "glmnet") {
  n_classes <- get_n_classes(training_data[,1])

  # Get out-of-fold predictions from base models (to avoid overfitting)
  meta_features <- get_oof_predictions(models, model_types, training_data, n_classes)

  # True labels
  true_labels <- training_data[,1]

  # Train meta-learner
  meta_model <- switch(meta_type,
                       "glmnet" = train_glmnet_meta(meta_features, true_labels, n_classes),
                       "randomforest" = train_rf_meta(meta_features, true_labels),
                       "xgboost" = train_xgb_meta(meta_features, true_labels, n_classes),
                       stop("Unknown meta-learner type"))

  return(list(
    model = meta_model,
    type = meta_type,
    n_base_models = length(models)
  ))
}

# Get out-of-fold predictions (cross-validation)
get_oof_predictions <- function(models, model_types, data, n_classes, n_folds = 5) {
  n_samples <- nrow(data)
  n_models <- length(models)

  # Initialize OOF prediction matrix
  if (n_classes == 2) {
    oof_preds <- matrix(0, nrow = n_samples, ncol = n_models)
  } else {
    oof_preds <- matrix(0, nrow = n_samples, ncol = n_models * n_classes)
  }

  # Create folds
  folds <- createFolds(data[,1], k = n_folds, list = TRUE)

  for (fold_idx in seq_along(folds)) {
    test_idx <- folds[[fold_idx]]
    train_idx <- setdiff(1:n_samples, test_idx)

    train_data <- data[train_idx, ]
    test_data <- data[test_idx, ]

    # For each model, retrain on fold and predict on held-out
    for (model_idx in seq_along(models)) {
      # Retrain model on this fold
      fold_model <- retrain_model(model_types[model_idx], train_data)

      # Get predictions for held-out samples
      pred_result <- get_model_predictions(fold_model, model_types[model_idx],
                                           test_data, n_classes)

      # Store OOF predictions
      if (n_classes == 2) {
        oof_preds[test_idx, model_idx] <- pred_result$scores
      } else {
        start_col <- (model_idx - 1) * n_classes + 1
        end_col <- model_idx * n_classes
        oof_preds[test_idx, start_col:end_col] <- pred_result$scores
      }
    }
  }

  return(oof_preds)
}

# Train glmnet meta-learner
train_glmnet_meta <- function(meta_features, true_labels, n_classes) {
  if (n_classes == 2) {
    y <- as.numeric(true_labels) - 1  # 0/1 encoding
    family <- "binomial"
  } else {
    y <- true_labels
    family <- "multinomial"
  }

  cv_fit <- cv.glmnet(x = as.matrix(meta_features), y = y, family = family,
                      alpha = 0.5, nfolds = 5)

  return(cv_fit)
}

# Train random forest meta-learner
train_rf_meta <- function(meta_features, true_labels) {
  rf_model <- randomForest(x = meta_features, y = true_labels,
                           ntree = 500, mtry = floor(sqrt(ncol(meta_features))))
  return(rf_model)
}

# Train XGBoost meta-learner
train_xgb_meta <- function(meta_features, true_labels, n_classes) {
  if (n_classes == 2) {
    y <- as.numeric(true_labels) - 1
    params <- list(objective = "binary:logistic", eval_metric = "auc")
  } else {
    y <- as.numeric(true_labels) - 1
    params <- list(objective = "multi:softprob", num_class = n_classes,
                   eval_metric = "mlogloss")
  }

  dtrain <- xgb.DMatrix(data = as.matrix(meta_features), label = y)
  xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100,
                         verbose = 0)

  return(xgb_model)
}

##########################
# Weight Optimization
##########################

# Optimize ensemble weights based on validation performance
optimize_ensemble_weights <- function(models, model_types, training_data,
                                      metric = "auc", n_folds = 5) {
  n_models <- length(models)
  n_classes <- get_n_classes(training_data[,1])

  # Get OOF predictions
  oof_preds <- get_oof_predictions_simple(models, model_types, training_data,
                                          n_classes, n_folds)

  # Optimize weights using optim
  initial_weights <- rep(1 / n_models, n_models)

  objective <- function(weights) {
    # Ensure weights sum to 1
    weights <- weights / sum(weights)

    # Calculate weighted ensemble predictions
    if (n_classes == 2) {
      ensemble_scores <- rowSums(sweep(oof_preds, 2, weights, "*"))
    } else {
      ensemble_scores <- matrix(0, nrow = nrow(oof_preds), ncol = n_classes)
      for (i in 1:n_models) {
        start_col <- (i - 1) * n_classes + 1
        end_col <- i * n_classes
        ensemble_scores <- ensemble_scores + oof_preds[, start_col:end_col] * weights[i]
      }
    }

    # Calculate metric (we minimize, so negate for maximization metrics)
    metric_value <- calculate_metric(training_data[,1], ensemble_scores, metric)
    return(-metric_value)  # Negate for minimization
  }

  result <- optim(par = initial_weights, fn = objective, method = "L-BFGS-B",
                  lower = rep(0, n_models), upper = rep(1, n_models))

  optimal_weights <- result$par / sum(result$par)
  return(optimal_weights)
}

# Simplified OOF predictions for weight optimization
get_oof_predictions_simple <- function(models, model_types, data, n_classes, n_folds) {
  # Simplified version - just use current models for speed
  n_samples <- nrow(data)
  n_models <- length(models)

  if (n_classes == 2) {
    oof_preds <- matrix(0, nrow = n_samples, ncol = n_models)
  } else {
    oof_preds <- matrix(0, nrow = n_samples, ncol = n_models * n_classes)
  }

  for (i in seq_along(models)) {
    pred_result <- get_model_predictions(models[[i]], model_types[i], data, n_classes)

    if (n_classes == 2) {
      oof_preds[, i] <- pred_result$scores
    } else {
      start_col <- (i - 1) * n_classes + 1
      end_col <- i * n_classes
      oof_preds[, start_col:end_col] <- pred_result$scores
    }
  }

  return(oof_preds)
}

##########################
# Helper Functions
##########################

# Get predictions from a single model
get_model_predictions <- function(model, model_type, data, n_classes) {
  # Extract predictions based on model type
  # Returns list(predictions = factor, scores = vector or matrix)

  result <- switch(model_type,
                   "randomforest" = get_rf_predictions(model, data, n_classes),
                   "svm" = get_svm_predictions(model, data, n_classes),
                   "elasticnet" = get_glmnet_predictions(model, data, n_classes),
                   "xgboost" = get_xgb_predictions(model, data, n_classes),
                   "knn" = get_knn_predictions(model, data, n_classes),
                   "naivebayes" = get_nb_predictions(model, data, n_classes),
                   stop("Unknown model type"))

  return(result)
}

# Placeholder prediction functions (implement based on existing code)
get_rf_predictions <- function(model, data, n_classes) {
  pred <- predict(model, newdata = data[,-1], type = "prob")
  if (n_classes == 2) {
    scores <- pred[, 2]
    predictions <- ifelse(scores > 0.5, 2, 1)
  } else {
    scores <- pred
    predictions <- apply(scores, 1, which.max)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

get_svm_predictions <- function(model, data, n_classes) {
  if (n_classes == 2) {
    pred <- predict(model, newdata = data[,-1], decision.values = TRUE)
    scores <- attr(pred, "decision.values")[,1]
    predictions <- ifelse(scores > 0, 1, 2)
  } else {
    pred <- predict(model, newdata = data[,-1], probability = TRUE)
    scores <- attr(pred, "probabilities")
    predictions <- apply(scores, 1, which.max)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

get_glmnet_predictions <- function(model, data, n_classes) {
  pred <- predict(model, newx = as.matrix(data[,-1]), s = "lambda.min", type = "response")
  if (n_classes == 2) {
    scores <- as.vector(pred)
    predictions <- ifelse(scores > 0.5, 2, 1)
  } else {
    scores <- pred[,,1]
    predictions <- apply(scores, 1, which.max)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

get_xgb_predictions <- function(model, data, n_classes) {
  dtest <- xgb.DMatrix(data = as.matrix(data[,-1]))
  pred <- predict(model, dtest)

  if (n_classes == 2) {
    scores <- pred
    predictions <- ifelse(scores > 0.5, 2, 1)
  } else {
    scores <- matrix(pred, ncol = n_classes, byrow = TRUE)
    predictions <- apply(scores, 1, which.max)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

get_knn_predictions <- function(model, data, n_classes) {
  # For KNN, model contains training data and k
  pred <- knn(train = model$train[,-1], test = data[,-1],
              cl = model$train[,1], k = model$k, prob = TRUE)
  probs <- attr(pred, "prob")

  if (n_classes == 2) {
    scores <- ifelse(as.numeric(pred) == 1, probs, 1 - probs)
    predictions <- as.numeric(pred)
  } else {
    # Multi-class KNN - simplified
    scores <- matrix(0, nrow = nrow(data), ncol = n_classes)
    predictions <- as.numeric(pred)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

get_nb_predictions <- function(model, data, n_classes) {
  pred <- predict(model, newdata = data[,-1], type = "raw")

  if (n_classes == 2) {
    scores <- pred[, 2]
    predictions <- ifelse(scores > 0.5, 2, 1)
  } else {
    scores <- pred
    predictions <- apply(scores, 1, which.max)
  }
  list(predictions = factor(predictions, levels = 1:n_classes), scores = scores)
}

# Calculate performance metric
calculate_metric <- function(true_labels, predicted_scores, metric = "auc") {
  n_classes <- length(levels(true_labels))

  switch(metric,
         "auc" = calculate_multiclass_auc(true_labels, predicted_scores),
         "accuracy" = {
           if (n_classes == 2) {
             preds <- ifelse(predicted_scores > 0.5, 2, 1)
           } else {
             preds <- apply(predicted_scores, 1, which.max)
           }
           mean(preds == as.numeric(true_labels))
         },
         "f1" = {
           # Simplified F1 calculation
           if (n_classes == 2) {
             preds <- ifelse(predicted_scores > 0.5, 2, 1)
           } else {
             preds <- apply(predicted_scores, 1, which.max)
           }
           tp <- sum(preds == 2 & as.numeric(true_labels) == 2)
           fp <- sum(preds == 2 & as.numeric(true_labels) == 1)
           fn <- sum(preds == 1 & as.numeric(true_labels) == 2)
           2 * tp / (2 * tp + fp + fn)
         },
         stop("Unknown metric"))
}

# Retrain model on new data
retrain_model <- function(model_type, training_data) {
  # This should call the appropriate model training function
  # Placeholder - implement based on existing model training code
  NULL
}

# Null coalescing operator
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

##########################
# Ensemble Evaluation
##########################

# Evaluate ensemble performance
evaluate_ensemble <- function(ensemble, test_data, true_labels, threshold = 0.5) {
  predictions <- predict_ensemble(ensemble, test_data, threshold)

  n_classes <- length(levels(true_labels))

  # Calculate metrics
  accuracy <- mean(predictions$predictions == true_labels)

  if (n_classes == 2) {
    auc_value <- calculate_multiclass_auc(true_labels, predictions$scores)
  } else {
    auc_value <- calculate_multiclass_auc(true_labels, predictions$scores)
  }

  # Confusion matrix
  cm <- table(Predicted = predictions$predictions, Actual = true_labels)

  list(
    accuracy = accuracy,
    auc = auc_value,
    confusion_matrix = cm,
    predictions = predictions$predictions,
    scores = predictions$scores
  )
}

# Compare ensemble with individual models
compare_ensemble_performance <- function(ensemble, test_data, true_labels, threshold = 0.5) {
  results <- list()

  # Ensemble performance
  ensemble_perf <- evaluate_ensemble(ensemble, test_data, true_labels, threshold)
  results$ensemble <- ensemble_perf

  # Individual model performances
  n_classes <- get_n_classes(true_labels)

  for (i in seq_along(ensemble$models)) {
    model_name <- paste0(ensemble$model_types[i], "_", i)
    pred_result <- get_model_predictions(ensemble$models[[i]],
                                         ensemble$model_types[i],
                                         test_data, n_classes)

    accuracy <- mean(pred_result$predictions == true_labels)
    auc_value <- calculate_multiclass_auc(true_labels, pred_result$scores)

    results[[model_name]] <- list(
      accuracy = accuracy,
      auc = auc_value
    )
  }

  return(results)
}

message("Ensemble system initialized")
