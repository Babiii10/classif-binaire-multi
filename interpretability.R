################################################################################
# INTERPRETABILITY MODULE - SHAP & LIME
################################################################################
# Description: Model interpretation using SHAP and LIME methods
# Features:
#   - SHAP (SHapley Additive exPlanations) for global/local explanations
#   - LIME (Local Interpretable Model-agnostic Explanations)
#   - Feature importance visualization
#   - Individual prediction explanations
#   - Supports all major model types (RF, XGBoost, SVM, ElasticNet, etc.)
#
# Dependencies (optional):
#   - DALEX: Unified interface for model explanations
#   - iml: Interpretable Machine Learning
#   - fastshap: Fast SHAP value computation
#   - ggplot2: Visualizations
################################################################################

# Check optional packages
INTERPRETABILITY_AVAILABLE <- list(
  dalex = requireNamespace("DALEX", quietly = TRUE),
  iml = requireNamespace("iml", quietly = TRUE),
  fastshap = requireNamespace("fastshap", quietly = TRUE),
  ggplot2 = requireNamespace("ggplot2", quietly = TRUE)
)

if (!any(unlist(INTERPRETABILITY_AVAILABLE))) {
  message("NOTE: Interpretability packages not found. Install for full features:")
  message("  install.packages(c('DALEX', 'iml', 'fastshap'))")
}

################################################################################
# SHAP EXPLANATIONS
################################################################################

#' Calculate SHAP values for a model
#'
#' @param model Trained model object
#' @param data Training data (data.frame)
#' @param newdata Data to explain (optional, defaults to sample of training data)
#' @param model_type Type of model ("randomforest", "xgboost", "svm", etc.)
#' @param nsim Number of Monte Carlo simulations for SHAP (default: 100)
#' @param sample_size Maximum samples to use for background data (default: 100)
#' @return List with SHAP values and visualizations
calculate_shap <- function(model, data, newdata = NULL, model_type = "randomforest",
                          nsim = 100, sample_size = 100) {

  if (!INTERPRETABILITY_AVAILABLE$fastshap && !INTERPRETABILITY_AVAILABLE$dalex) {
    warning("SHAP requires 'fastshap' or 'DALEX' package")
    return(NULL)
  }

  tryCatch({
    # Sample background data if too large
    if (nrow(data) > sample_size) {
      data_sample <- data[sample(nrow(data), sample_size), ]
    } else {
      data_sample <- data
    }

    # Default newdata to small sample
    if (is.null(newdata)) {
      newdata <- data[sample(nrow(data), min(10, nrow(data))), ]
    }

    # Create prediction function based on model type
    pred_wrapper <- create_predict_wrapper(model, model_type)

    # Calculate SHAP values using fastshap
    if (INTERPRETABILITY_AVAILABLE$fastshap) {

      # Get feature names (exclude target variable)
      feature_names <- setdiff(names(data), c("group", "Group", "class", "Class"))
      X_train <- data_sample[, feature_names, drop = FALSE]
      X_explain <- newdata[, feature_names, drop = FALSE]

      shap_values <- fastshap::explain(
        object = model,
        X = X_train,
        newdata = X_explain,
        pred_wrapper = pred_wrapper,
        nsim = nsim
      )

      # Calculate feature importance (mean absolute SHAP)
      feature_importance <- data.frame(
        feature = colnames(shap_values),
        importance = colMeans(abs(shap_values)),
        stringsAsFactors = FALSE
      )
      feature_importance <- feature_importance[order(-feature_importance$importance), ]

      result <- list(
        shap_values = shap_values,
        feature_importance = feature_importance,
        method = "fastshap"
      )

    } else if (INTERPRETABILITY_AVAILABLE$dalex) {
      # Fallback to DALEX
      result <- calculate_shap_dalex(model, data_sample, newdata, model_type)
    }

    # Add visualization if ggplot2 available
    if (INTERPRETABILITY_AVAILABLE$ggplot2 && !is.null(result)) {
      result$plots <- create_shap_plots(result)
    }

    return(result)

  }, error = function(e) {
    warning(paste("SHAP calculation failed:", e$message))
    return(NULL)
  })
}

#' SHAP calculation using DALEX
calculate_shap_dalex <- function(model, data, newdata, model_type) {

  if (!requireNamespace("DALEX", quietly = TRUE)) {
    return(NULL)
  }

  # Get feature names
  feature_names <- setdiff(names(data), c("group", "Group", "class", "Class"))
  X_train <- data[, feature_names, drop = FALSE]
  y_train <- data$group

  # Create DALEX explainer
  explainer <- DALEX::explain(
    model = model,
    data = X_train,
    y = y_train,
    predict_function = create_predict_wrapper(model, model_type),
    label = model_type
  )

  # Calculate SHAP
  X_explain <- newdata[, feature_names, drop = FALSE]
  shap <- DALEX::predict_parts(
    explainer,
    new_observation = X_explain[1, , drop = FALSE],
    type = "shap"
  )

  result <- list(
    explainer = explainer,
    shap_dalex = shap,
    method = "dalex"
  )

  return(result)
}

#' Create SHAP visualization plots
create_shap_plots <- function(shap_result) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return(NULL)
  }

  plots <- list()

  # Feature importance plot
  if (!is.null(shap_result$feature_importance)) {

    top_features <- head(shap_result$feature_importance, 20)

    plots$feature_importance <- ggplot2::ggplot(
      top_features,
      ggplot2::aes(x = reorder(feature, importance), y = importance)
    ) +
      ggplot2::geom_bar(stat = "identity", fill = "steelblue") +
      ggplot2::coord_flip() +
      ggplot2::labs(
        title = "SHAP Feature Importance",
        subtitle = "Mean absolute SHAP values",
        x = "Feature",
        y = "Mean |SHAP value|"
      ) +
      ggplot2::theme_minimal()
  }

  # Summary plot (beeswarm style)
  if (!is.null(shap_result$shap_values)) {

    # Prepare data for beeswarm plot
    shap_long <- reshape2::melt(
      as.data.frame(shap_result$shap_values),
      variable.name = "feature",
      value.name = "shap_value"
    )

    # Select top features
    top_features <- head(shap_result$feature_importance$feature, 15)
    shap_long <- shap_long[shap_long$feature %in% top_features, ]

    plots$summary <- ggplot2::ggplot(
      shap_long,
      ggplot2::aes(x = shap_value, y = reorder(feature, shap_value, FUN = function(x) mean(abs(x))))
    ) +
      ggplot2::geom_jitter(alpha = 0.5, color = "steelblue", height = 0.2) +
      ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
      ggplot2::labs(
        title = "SHAP Summary Plot",
        subtitle = "Distribution of SHAP values per feature",
        x = "SHAP value",
        y = "Feature"
      ) +
      ggplot2::theme_minimal()
  }

  return(plots)
}

################################################################################
# LIME EXPLANATIONS
################################################################################

#' Calculate LIME explanations for predictions
#'
#' @param model Trained model object
#' @param data Training data (data.frame)
#' @param newdata Single observation to explain (data.frame with 1 row)
#' @param model_type Type of model
#' @param n_features Number of features to include in explanation (default: 5)
#' @param n_permutations Number of permutations for LIME (default: 5000)
#' @return LIME explanation object
calculate_lime <- function(model, data, newdata, model_type = "randomforest",
                          n_features = 5, n_permutations = 5000) {

  if (!INTERPRETABILITY_AVAILABLE$iml && !INTERPRETABILITY_AVAILABLE$dalex) {
    warning("LIME requires 'iml' or 'DALEX' package")
    return(NULL)
  }

  tryCatch({

    # Get feature names
    feature_names <- setdiff(names(data), c("group", "Group", "class", "Class"))
    X_train <- data[, feature_names, drop = FALSE]
    X_explain <- newdata[, feature_names, drop = FALSE]

    if (INTERPRETABILITY_AVAILABLE$iml) {
      # Use iml package

      # Create predictor object
      predictor <- iml::Predictor$new(
        model = model,
        data = X_train,
        predict.function = create_predict_wrapper(model, model_type),
        type = "prob"
      )

      # Create LIME explainer
      lime_explainer <- iml::LocalModel$new(
        predictor,
        x.interest = X_explain,
        k = n_features
      )

      result <- list(
        lime_explanation = lime_explainer,
        predictor = predictor,
        method = "iml"
      )

      # Add visualization
      if (INTERPRETABILITY_AVAILABLE$ggplot2) {
        result$plot <- lime_explainer$plot()
      }

    } else if (INTERPRETABILITY_AVAILABLE$dalex) {
      # Fallback to DALEX
      result <- calculate_lime_dalex(model, data, newdata, model_type, n_features)
    }

    return(result)

  }, error = function(e) {
    warning(paste("LIME calculation failed:", e$message))
    return(NULL)
  })
}

#' LIME calculation using DALEX
calculate_lime_dalex <- function(model, data, newdata, model_type, n_features) {

  if (!requireNamespace("DALEX", quietly = TRUE)) {
    return(NULL)
  }

  feature_names <- setdiff(names(data), c("group", "Group", "class", "Class"))
  X_train <- data[, feature_names, drop = FALSE]
  y_train <- data$group

  # Create explainer
  explainer <- DALEX::explain(
    model = model,
    data = X_train,
    y = y_train,
    predict_function = create_predict_wrapper(model, model_type),
    label = model_type
  )

  # Calculate LIME-like local explanation
  X_explain <- newdata[, feature_names, drop = FALSE]
  lime <- DALEX::predict_parts(
    explainer,
    new_observation = X_explain[1, , drop = FALSE],
    type = "break_down"
  )

  result <- list(
    explainer = explainer,
    lime_dalex = lime,
    method = "dalex"
  )

  return(result)
}

################################################################################
# UNIFIED EXPLANATION INTERFACE
################################################################################

#' Generate comprehensive model explanation
#'
#' @param model Trained model
#' @param data Training data
#' @param newdata Optional data to explain (for local explanations)
#' @param model_type Model type
#' @param methods Vector of methods to use: c("shap", "lime", "permutation")
#' @param output_file Optional file to save HTML report
#' @return List with all explanations and plots
explain_model <- function(model, data, newdata = NULL, model_type = "randomforest",
                         methods = c("shap", "permutation"), output_file = NULL) {

  message("Generating model explanations...")

  results <- list()

  # SHAP explanations (global)
  if ("shap" %in% methods) {
    message("  - Calculating SHAP values...")
    results$shap <- calculate_shap(model, data, newdata, model_type, nsim = 50)
  }

  # LIME explanations (local, requires newdata)
  if ("lime" %in% methods && !is.null(newdata)) {
    message("  - Calculating LIME explanations...")
    if (nrow(newdata) > 5) {
      newdata_sample <- newdata[1:5, ]
    } else {
      newdata_sample <- newdata
    }
    results$lime <- lapply(1:nrow(newdata_sample), function(i) {
      calculate_lime(model, data, newdata_sample[i, , drop = FALSE], model_type)
    })
  }

  # Permutation feature importance
  if ("permutation" %in% methods) {
    message("  - Calculating permutation importance...")
    results$permutation <- calculate_permutation_importance(model, data, model_type)
  }

  # Generate HTML report if requested
  if (!is.null(output_file)) {
    message("  - Generating HTML report...")
    generate_interpretation_report(results, output_file, model_type)
  }

  message("Explanation complete!")
  return(results)
}

#' Calculate permutation feature importance
calculate_permutation_importance <- function(model, data, model_type, n_repeats = 10) {

  tryCatch({

    feature_names <- setdiff(names(data), c("group", "Group", "class", "Class"))
    X <- data[, feature_names, drop = FALSE]
    y <- data$group

    # Get baseline predictions
    pred_wrapper <- create_predict_wrapper(model, model_type)
    baseline_pred <- pred_wrapper(X)

    # Calculate baseline accuracy
    if (is.matrix(baseline_pred)) {
      baseline_pred <- apply(baseline_pred, 1, which.max)
    }
    baseline_accuracy <- mean(baseline_pred == as.numeric(y))

    # Permute each feature and measure drop in accuracy
    importance <- sapply(feature_names, function(feat) {

      accuracy_drops <- numeric(n_repeats)

      for (i in 1:n_repeats) {
        X_permuted <- X
        X_permuted[[feat]] <- sample(X_permuted[[feat]])

        preds <- pred_wrapper(X_permuted)
        if (is.matrix(preds)) {
          preds <- apply(preds, 1, which.max)
        }

        accuracy_drops[i] <- baseline_accuracy - mean(preds == as.numeric(y))
      }

      mean(accuracy_drops)
    })

    # Create data frame
    importance_df <- data.frame(
      feature = names(importance),
      importance = as.numeric(importance),
      stringsAsFactors = FALSE
    )
    importance_df <- importance_df[order(-importance_df$importance), ]

    return(importance_df)

  }, error = function(e) {
    warning(paste("Permutation importance calculation failed:", e$message))
    return(NULL)
  })
}

################################################################################
# PREDICTION WRAPPERS
################################################################################

#' Create prediction wrapper function for different model types
create_predict_wrapper <- function(model, model_type) {

  wrapper <- function(newdata) {

    tryCatch({

      if (model_type == "randomforest") {
        pred <- predict(model, newdata, type = "prob")

      } else if (model_type == "xgboost") {
        # XGBoost needs matrix
        X_mat <- as.matrix(newdata)
        pred <- predict(model, X_mat, type = "prob")

      } else if (model_type %in% c("svm", "svmlinear", "svmradial")) {
        pred <- attr(predict(model, newdata, probability = TRUE), "probabilities")

      } else if (model_type %in% c("elasticnet", "lasso", "ridge")) {
        # glmnet models
        X_mat <- as.matrix(newdata)
        pred <- predict(model, X_mat, type = "response", s = "lambda.min")

      } else if (model_type == "knn") {
        # KNN returns class predictions, need to convert
        pred <- predict(model, newdata)

      } else {
        # Generic prediction
        pred <- predict(model, newdata, type = "prob")
      }

      # Ensure matrix format for multi-class
      if (!is.matrix(pred) && !is.data.frame(pred)) {
        pred <- as.matrix(pred)
      }

      return(pred)

    }, error = function(e) {
      warning(paste("Prediction wrapper failed:", e$message))
      return(NULL)
    })
  }

  return(wrapper)
}

################################################################################
# HTML REPORT GENERATION
################################################################################

#' Generate HTML interpretation report
generate_interpretation_report <- function(results, output_file, model_type) {

  html_content <- paste0("
<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>Model Interpretation Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
    h2 { color: #34495e; margin-top: 30px; border-left: 4px solid #3498db; padding-left: 15px; }
    h3 { color: #7f8c8d; }
    .info-box { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 15px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #3498db; color: white; }
    tr:hover { background-color: #f5f5f5; }
    .highlight { background-color: #fff9c4; font-weight: bold; }
    .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d; font-size: 0.9em; }
  </style>
</head>
<body>
  <div class='container'>
    <h1>🔍 Model Interpretation Report</h1>
    <div class='info-box'>
      <strong>Model Type:</strong> ", model_type, "<br>
      <strong>Generation Date:</strong> ", Sys.time(), "<br>
      <strong>Methods:</strong> ", paste(names(results), collapse = ", "), "
    </div>
")

  # SHAP results
  if (!is.null(results$shap) && !is.null(results$shap$feature_importance)) {
    html_content <- paste0(html_content, "
    <h2>📊 SHAP Feature Importance</h2>
    <p>Features ranked by their average impact on model predictions (mean absolute SHAP value).</p>
    <table>
      <tr>
        <th>Rank</th>
        <th>Feature</th>
        <th>Importance</th>
      </tr>
")

    for (i in 1:min(20, nrow(results$shap$feature_importance))) {
      feat <- results$shap$feature_importance[i, ]
      html_content <- paste0(html_content, "
      <tr", if(i <= 3) " class='highlight'" else "", ">
        <td>", i, "</td>
        <td>", feat$feature, "</td>
        <td>", round(feat$importance, 4), "</td>
      </tr>
")
    }

    html_content <- paste0(html_content, "
    </table>
")
  }

  # Permutation importance
  if (!is.null(results$permutation)) {
    html_content <- paste0(html_content, "
    <h2>🔄 Permutation Feature Importance</h2>
    <p>Drop in model accuracy when each feature is randomly shuffled.</p>
    <table>
      <tr>
        <th>Rank</th>
        <th>Feature</th>
        <th>Importance Drop</th>
      </tr>
")

    for (i in 1:min(20, nrow(results$permutation))) {
      feat <- results$permutation[i, ]
      html_content <- paste0(html_content, "
      <tr", if(i <= 3) " class='highlight'" else "", ">
        <td>", i, "</td>
        <td>", feat$feature, "</td>
        <td>", round(feat$importance, 4), "</td>
      </tr>
")
    }

    html_content <- paste0(html_content, "
    </table>
")
  }

  # Footer
  html_content <- paste0(html_content, "
    <div class='footer'>
      <p><strong>Interpretation Methods:</strong></p>
      <ul>
        <li><strong>SHAP:</strong> SHapley Additive exPlanations - Shows contribution of each feature to individual predictions</li>
        <li><strong>Permutation Importance:</strong> Measures feature importance by randomly shuffling values</li>
      </ul>
    </div>
  </div>
</body>
</html>
")

  # Write to file
  tryCatch({
    writeLines(html_content, output_file)
    message("Interpretation report saved to: ", output_file)
  }, error = function(e) {
    warning(paste("Could not write report:", e$message))
  })
}

################################################################################
# EXPORT
################################################################################

message("✓ Interpretability module loaded (SHAP/LIME support)")
