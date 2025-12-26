##########################
# Overfitting Detection System
# Automatic detection and mitigation of overfitting
##########################

##########################
# Main Overfitting Detection
##########################

detect_overfitting <- function(train_metrics, val_metrics, threshold_severe = 0.15,
                              threshold_moderate = 0.08, detailed = TRUE) {

  # Calculate differences
  auc_diff <- train_metrics$auc - val_metrics$auc
  acc_diff <- train_metrics$accuracy - val_metrics$accuracy

  # Additional metrics if available
  sensitivity_diff <- if(!is.null(train_metrics$sensitivity) && !is.null(val_metrics$sensitivity)) {
    train_metrics$sensitivity - val_metrics$sensitivity
  } else NULL

  specificity_diff <- if(!is.null(train_metrics$specificity) && !is.null(val_metrics$specificity)) {
    train_metrics$specificity - val_metrics$specificity
  } else NULL

  # Determine status
  status <- if(auc_diff > threshold_severe || acc_diff > threshold_severe) {
    "severe_overfitting"
  } else if(auc_diff > threshold_moderate || acc_diff > threshold_moderate) {
    "moderate_overfitting"
  } else if(auc_diff > 0.05 || acc_diff > 0.05) {
    "mild_overfitting"
  } else if(auc_diff < 0.02 && acc_diff < 0.02) {
    "good_generalization"
  } else {
    "acceptable"
  }

  # Generate suggestions
  suggestions <- generate_overfitting_suggestions(status, auc_diff, acc_diff)

  # Detailed analysis
  detailed_analysis <- if(detailed) {
    analyze_overfitting_patterns(train_metrics, val_metrics)
  } else NULL

  result <- list(
    status = status,
    severity_score = calculate_severity_score(auc_diff, acc_diff),
    metrics = list(
      auc_diff = round(auc_diff, 4),
      acc_diff = round(acc_diff, 4),
      sensitivity_diff = if(!is.null(sensitivity_diff)) round(sensitivity_diff, 4) else NULL,
      specificity_diff = if(!is.null(specificity_diff)) round(specificity_diff, 4) else NULL
    ),
    train_performance = train_metrics,
    val_performance = val_metrics,
    suggestions = suggestions,
    detailed_analysis = detailed_analysis
  )

  class(result) <- c("overfitting_analysis", "list")
  return(result)
}

##########################
# Severity Score
##########################

calculate_severity_score <- function(auc_diff, acc_diff) {
  # Score from 0 (perfect) to 10 (severe overfitting)
  score <- (auc_diff * 20 + acc_diff * 30) / 2
  score <- min(max(score, 0), 10)
  return(round(score, 2))
}

##########################
# Generate Suggestions
##########################

generate_overfitting_suggestions <- function(status, auc_diff, acc_diff) {

  suggestions <- list()

  if(status == "severe_overfitting") {
    suggestions$priority <- "high"
    suggestions$actions <- c(
      "🔴 URGENT: Réduire drastiquement la complexité du modèle",
      "Augmenter la régularisation (lambda, alpha, C parameter)",
      "Réduire le nombre de features (feature selection plus agressive)",
      "Augmenter la taille du dataset d'entraînement",
      "Utiliser early stopping avec patience réduite",
      "Considérer des modèles plus simples (ElasticNet, Naive Bayes)",
      "Appliquer dropout (pour réseaux de neurones si applicable)"
    )
    suggestions$regularization <- list(
      elasticnet = "Augmenter alpha à 0.8-1.0 (plus proche de Lasso)",
      xgboost = "Réduire max_depth à 3-4, augmenter min_child_weight à 5",
      randomforest = "Augmenter min_samples_leaf à 10-20",
      svm = "Réduire C (cost) à 0.1-1"
    )

  } else if(status == "moderate_overfitting") {
    suggestions$priority <- "medium"
    suggestions$actions <- c(
      "🟡 Ajuster la régularisation",
      "Réduire légèrement la complexité du modèle",
      "Utiliser validation croisée pour tuning",
      "Vérifier la qualité des features (corrélations)",
      "Considérer ensemble methods pour plus de robustesse"
    )
    suggestions$regularization <- list(
      elasticnet = "Ajuster alpha à 0.5-0.7",
      xgboost = "Réduire max_depth de 1-2 niveaux",
      randomforest = "Augmenter min_samples_split",
      svm = "Ajuster gamma (réduire de 50%)"
    )

  } else if(status == "mild_overfitting") {
    suggestions$priority <- "low"
    suggestions$actions <- c(
      "Performance acceptable mais améliorable",
      "Monitoring lors de nouvelles prédictions",
      "Considérer légère augmentation de régularisation",
      "Validation croisée pour confirmer les performances"
    )

  } else if(status == "good_generalization") {
    suggestions$priority <- "none"
    suggestions$actions <- c(
      "✅ Excellente généralisation !",
      "Le modèle est bien calibré",
      "Continuer le monitoring sur nouvelles données",
      "Documenter les paramètres pour reproduction"
    )

  } else {  # acceptable
    suggestions$priority <- "low"
    suggestions$actions <- c(
      "Performance acceptable",
      "Monitoring recommandé",
      "Validation sur nouvelles données conseillée"
    )
  }

  # Add data-driven suggestions
  if(auc_diff > 0.1 && acc_diff < 0.05) {
    suggestions$notes <- c(suggestions$notes,
                          "AUC gap important mais accuracy stable: vérifier la calibration des probabilités")
  }

  if(acc_diff > 0.1 && auc_diff < 0.05) {
    suggestions$notes <- c(suggestions$notes,
                          "Accuracy gap important mais AUC stable: vérifier le seuil de classification")
  }

  return(suggestions)
}

##########################
# Detailed Analysis
##########################

analyze_overfitting_patterns <- function(train_metrics, val_metrics) {

  analysis <- list()

  # 1. Performance degradation pattern
  degradation <- list(
    auc = (train_metrics$auc - val_metrics$auc) / train_metrics$auc * 100,
    accuracy = (train_metrics$accuracy - val_metrics$accuracy) / train_metrics$accuracy * 100
  )

  analysis$degradation_percentage <- degradation

  # 2. Prediction confidence analysis
  if(!is.null(train_metrics$scores) && !is.null(val_metrics$scores)) {
    train_confidence <- mean(abs(train_metrics$scores - 0.5))
    val_confidence <- mean(abs(val_metrics$scores - 0.5))

    analysis$confidence_gap <- train_confidence - val_confidence

    if(analysis$confidence_gap > 0.1) {
      analysis$confidence_note <- "Modèle trop confiant sur train, moins sur validation (signe d'overfitting)"
    }
  }

  # 3. Class-specific overfitting
  if(!is.null(train_metrics$confusion_matrix) && !is.null(val_metrics$confusion_matrix)) {
    train_cm <- train_metrics$confusion_matrix
    val_cm <- val_metrics$confusion_matrix

    # Per-class accuracy
    train_class_acc <- diag(train_cm) / rowSums(train_cm)
    val_class_acc <- diag(val_cm) / rowSums(val_cm)

    class_diff <- train_class_acc - val_class_acc

    analysis$class_specific <- data.frame(
      class = names(class_diff),
      train_accuracy = round(train_class_acc, 3),
      val_accuracy = round(val_class_acc, 3),
      difference = round(class_diff, 3),
      overfitting_severe = class_diff > 0.15
    )

    # Identify most overfitted classes
    worst_classes <- names(class_diff)[class_diff > 0.1]
    if(length(worst_classes) > 0) {
      analysis$worst_classes <- worst_classes
      analysis$class_note <- sprintf("Classes %s montrent overfitting sévère",
                                    paste(worst_classes, collapse = ", "))
    }
  }

  # 4. Learning curve recommendation
  analysis$learning_curve_recommendation <- if(degradation$auc > 20) {
    "Recommandé: tracer learning curve pour identifier si plus de données aideraient"
  } else {
    "Learning curve non critique mais peut être informative"
  }

  return(analysis)
}

##########################
# Overfitting Mitigation
##########################

suggest_model_adjustments <- function(model_type, overfitting_analysis) {

  status <- overfitting_analysis$status

  if(status %in% c("good_generalization", "acceptable")) {
    return(list(
      message = "Pas d'ajustement nécessaire",
      params = NULL
    ))
  }

  # Model-specific adjustments
  adjustments <- switch(model_type,

    "randomforest" = list(
      current_issue = "Arbres trop profonds ou trop nombreux",
      suggested_params = if(status == "severe_overfitting") {
        list(
          ntree = "Réduire de 50% (ex: 1000 → 500)",
          max_depth = "Limiter à 10-15",
          min_samples_split = "Augmenter à 10-20",
          min_samples_leaf = "Augmenter à 5-10",
          max_features = "Réduire (ex: sqrt → log2)"
        )
      } else {
        list(
          min_samples_split = "Augmenter légèrement (+2-5)",
          min_samples_leaf = "Augmenter légèrement (+1-2)"
        )
      }
    ),

    "xgboost" = list(
      current_issue = "Arbres trop profonds ou learning rate trop élevé",
      suggested_params = if(status == "severe_overfitting") {
        list(
          max_depth = "Réduire à 3-4",
          eta = "Réduire à 0.01-0.05",
          min_child_weight = "Augmenter à 5-10",
          gamma = "Augmenter à 1-5",
          subsample = "Réduire à 0.6-0.8",
          colsample_bytree = "Réduire à 0.6-0.8",
          lambda = "Augmenter régularisation L2",
          alpha = "Ajouter régularisation L1"
        )
      } else {
        list(
          max_depth = "Réduire de 1-2",
          eta = "Réduire de 30%",
          min_child_weight = "Augmenter légèrement"
        )
      }
    ),

    "svm" = list(
      current_issue = "Paramètre C trop élevé ou gamma mal calibré",
      suggested_params = if(status == "severe_overfitting") {
        list(
          C = "Réduire drastiquement (÷ 10)",
          gamma = "Si radial kernel, réduire (÷ 5-10)",
          kernel = "Considérer kernel linear (plus simple)"
        )
      } else {
        list(
          C = "Réduire de 30-50%",
          gamma = "Ajuster si kernel radial"
        )
      }
    ),

    "elasticnet" = list(
      current_issue = "Régularisation insuffisante",
      suggested_params = if(status == "severe_overfitting") {
        list(
          alpha = "Augmenter vers 1.0 (Lasso pur)",
          lambda = "Augmenter (tester lambda.1se au lieu de lambda.min)"
        )
      } else {
        list(
          alpha = "Augmenter légèrement (+0.1-0.2)",
          lambda = "Considérer lambda.1se"
        )
      }
    ),

    "knn" = list(
      current_issue = "K trop petit (modèle trop flexible)",
      suggested_params = if(status == "severe_overfitting") {
        list(
          k = "Augmenter significativement (× 2-3)"
        )
      } else {
        list(
          k = "Augmenter légèrement (+2-5)"
        )
      }
    ),

    list(
      message = "Ajustements génériques recommandés",
      suggested_params = list(
        general = "Augmenter régularisation, réduire complexité"
      )
    )
  )

  return(adjustments)
}

##########################
# Visualization
##########################

plot_overfitting_analysis <- function(overfitting_analysis) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    message("ggplot2 required for plotting")
    return(NULL)
  }

  # Prepare data
  metrics <- overfitting_analysis$metrics

  comparison_data <- data.frame(
    metric = rep(c("AUC", "Accuracy"), each = 2),
    dataset = rep(c("Train", "Validation"), 2),
    value = c(
      overfitting_analysis$train_performance$auc,
      overfitting_analysis$val_performance$auc,
      overfitting_analysis$train_performance$accuracy,
      overfitting_analysis$val_performance$accuracy
    )
  )

  # Create plot
  p <- ggplot(comparison_data, aes(x = metric, y = value, fill = dataset)) +
    geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    geom_text(aes(label = sprintf("%.3f", value)),
              position = position_dodge(width = 0.7),
              vjust = -0.5, size = 4) +
    scale_fill_manual(values = c("Train" = "#3498db", "Validation" = "#e74c3c")) +
    ylim(0, 1.1) +
    labs(
      title = sprintf("Analyse d'Overfitting - Status: %s",
                     overfitting_analysis$status),
      subtitle = sprintf("Différence AUC: %.3f | Différence Accuracy: %.3f",
                        metrics$auc_diff, metrics$acc_diff),
      x = "Métrique",
      y = "Score",
      fill = "Dataset"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray30"),
      legend.position = "top"
    )

  # Add status color indicator
  status_color <- switch(overfitting_analysis$status,
    "severe_overfitting" = "#e74c3c",
    "moderate_overfitting" = "#f39c12",
    "mild_overfitting" = "#f1c40f",
    "good_generalization" = "#27ae60",
    "#95a5a6"
  )

  p <- p + theme(plot.title = element_text(color = status_color))

  return(p)
}

##########################
# Print Method
##########################

print.overfitting_analysis <- function(x, ...) {
  cat("===== Overfitting Analysis =====\n\n")

  cat(sprintf("Status: %s\n", toupper(x$status)))
  cat(sprintf("Severity Score: %.2f / 10\n\n", x$severity_score))

  cat("Performance Gaps:\n")
  cat(sprintf("  AUC Difference:      %.4f (%.1f%%)\n",
              x$metrics$auc_diff,
              x$metrics$auc_diff / x$train_performance$auc * 100))
  cat(sprintf("  Accuracy Difference: %.4f (%.1f%%)\n\n",
              x$metrics$acc_diff,
              x$metrics$acc_diff / x$train_performance$accuracy * 100))

  cat(sprintf("Priority: %s\n\n", toupper(x$suggestions$priority)))

  cat("Recommended Actions:\n")
  for(action in x$suggestions$actions) {
    cat(sprintf("  • %s\n", action))
  }

  if(!is.null(x$detailed_analysis$class_note)) {
    cat(sprintf("\n⚠️  %s\n", x$detailed_analysis$class_note))
  }

  cat("\n================================\n")
}

##########################
# Export Report
##########################

export_overfitting_report <- function(overfitting_analysis, filepath = "overfitting_report.txt") {

  sink(filepath)
  print(overfitting_analysis)

  if(!is.null(overfitting_analysis$suggestions$regularization)) {
    cat("\nModel-Specific Regularization Suggestions:\n")
    for(model in names(overfitting_analysis$suggestions$regularization)) {
      cat(sprintf("\n%s:\n", model))
      cat(sprintf("  %s\n", overfitting_analysis$suggestions$regularization[[model]]))
    }
  }

  if(!is.null(overfitting_analysis$detailed_analysis)) {
    cat("\nDetailed Analysis:\n")
    if(!is.null(overfitting_analysis$detailed_analysis$class_specific)) {
      cat("\nPer-Class Performance:\n")
      print(overfitting_analysis$detailed_analysis$class_specific)
    }
  }

  sink()

  message(sprintf("Overfitting report exported to: %s", filepath))
}

message("Overfitting detection system loaded")
