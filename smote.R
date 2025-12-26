################################################################################
# SMOTE & IMBALANCED DATA HANDLING MODULE
################################################################################
# Description: Handle imbalanced classification datasets
# Features:
#   - SMOTE (Synthetic Minority Over-sampling Technique)
#   - ADASYN (Adaptive Synthetic Sampling)
#   - Random oversampling
#   - Random undersampling
#   - Hybrid methods (combination of over/under sampling)
#   - User choice: apply to training and/or validation sets
#   - Automatic imbalance detection
#   - Before/after visualizations
#
# Dependencies (optional):
#   - smotefamily: SMOTE and ADASYN implementations
#   - ROSE: Random Over-Sampling Examples
#   - DMwR: Data Mining with R (alternative SMOTE)
################################################################################

# Check optional packages
SMOTE_AVAILABLE <- list(
  smotefamily = requireNamespace("smotefamily", quietly = TRUE),
  ROSE = requireNamespace("ROSE", quietly = TRUE),
  DMwR = requireNamespace("DMwR", quietly = TRUE)
)

if (!any(unlist(SMOTE_AVAILABLE))) {
  message("NOTE: Imbalance handling requires 'smotefamily' or 'ROSE' package")
  message("  install.packages(c('smotefamily', 'ROSE'))")
}

################################################################################
# IMBALANCE DETECTION
################################################################################

#' Detect class imbalance in dataset
#'
#' @param data Data frame with classification data
#' @param target_var Name of target variable (default: "group")
#' @param threshold_ratio Ratio threshold for imbalance (default: 2.0)
#' @return List with imbalance information
detect_class_imbalance <- function(data, target_var = "group", threshold_ratio = 2.0) {

  tryCatch({

    # Get class distribution
    class_counts <- table(data[[target_var]])
    class_props <- prop.table(class_counts)

    # Calculate imbalance ratio (majority/minority)
    max_count <- max(class_counts)
    min_count <- min(class_counts)
    imbalance_ratio <- max_count / min_count

    # Determine severity
    severity <- if (imbalance_ratio >= 10) {
      "severe"
    } else if (imbalance_ratio >= 5) {
      "high"
    } else if (imbalance_ratio >= threshold_ratio) {
      "moderate"
    } else {
      "balanced"
    }

    result <- list(
      is_imbalanced = imbalance_ratio >= threshold_ratio,
      imbalance_ratio = imbalance_ratio,
      severity = severity,
      class_counts = class_counts,
      class_proportions = class_props,
      majority_class = names(which.max(class_counts)),
      minority_class = names(which.min(class_counts)),
      recommendation = get_imbalance_recommendation(severity, imbalance_ratio)
    )

    return(result)

  }, error = function(e) {
    warning(paste("Imbalance detection failed:", e$message))
    return(NULL)
  })
}

#' Get recommendations based on imbalance severity
get_imbalance_recommendation <- function(severity, ratio) {

  if (severity == "balanced") {
    return("No resampling needed - classes are balanced")
  } else if (severity == "moderate") {
    return(paste0("Consider: Random oversampling or class weights (ratio: ", round(ratio, 2), ":1)"))
  } else if (severity == "high") {
    return(paste0("Recommended: SMOTE or hybrid sampling (ratio: ", round(ratio, 2), ":1)"))
  } else {
    return(paste0("Critical: Use SMOTE + undersampling or ADASYN (ratio: ", round(ratio, 2), ":1)"))
  }
}

################################################################################
# SMOTE IMPLEMENTATION
################################################################################

#' Apply SMOTE to balance dataset
#'
#' @param data Data frame with features and target
#' @param target_var Name of target variable
#' @param perc_over Percentage of oversampling for minority class (default: 200)
#' @param perc_under Percentage of undersampling for majority class (default: 200)
#' @param k Number of nearest neighbors for SMOTE (default: 5)
#' @return Balanced dataset
apply_smote <- function(data, target_var = "group", perc_over = 200,
                       perc_under = 200, k = 5) {

  if (!SMOTE_AVAILABLE$smotefamily && !SMOTE_AVAILABLE$DMwR) {
    warning("SMOTE requires 'smotefamily' or 'DMwR' package")
    return(data)
  }

  tryCatch({

    message("Applying SMOTE...")

    # Prepare data
    feature_names <- setdiff(names(data), c(target_var, "group", "Group", "class", "Class"))
    X <- data[, feature_names, drop = FALSE]
    y <- data[[target_var]]

    # Combine for SMOTE
    smote_data <- cbind(X, target = y)

    # Apply SMOTE
    if (SMOTE_AVAILABLE$smotefamily) {

      # Use smotefamily package
      result <- smotefamily::SMOTE(
        X = smote_data[, feature_names],
        target = smote_data$target,
        K = k,
        dup_size = perc_over / 100
      )

      balanced_data <- result$data
      names(balanced_data)[names(balanced_data) == "class"] <- target_var

    } else if (SMOTE_AVAILABLE$DMwR) {

      # Use DMwR package
      formula_str <- paste(target_var, "~ .")
      balanced_data <- DMwR::SMOTE(
        as.formula(formula_str),
        data = smote_data,
        perc.over = perc_over,
        perc.under = perc_under,
        k = k
      )
    }

    # Report results
    original_counts <- table(data[[target_var]])
    new_counts <- table(balanced_data[[target_var]])

    message("  Original distribution: ", paste(names(original_counts), "=", original_counts, collapse = ", "))
    message("  New distribution:      ", paste(names(new_counts), "=", new_counts, collapse = ", "))

    return(balanced_data)

  }, error = function(e) {
    warning(paste("SMOTE failed:", e$message))
    message("  Returning original data")
    return(data)
  })
}

################################################################################
# ADASYN IMPLEMENTATION
################################################################################

#' Apply ADASYN for adaptive synthetic sampling
#'
#' @param data Data frame
#' @param target_var Target variable name
#' @param k Number of nearest neighbors (default: 5)
#' @return Balanced dataset
apply_adasyn <- function(data, target_var = "group", k = 5) {

  if (!SMOTE_AVAILABLE$smotefamily) {
    warning("ADASYN requires 'smotefamily' package")
    message("  Falling back to SMOTE")
    return(apply_smote(data, target_var, k = k))
  }

  tryCatch({

    message("Applying ADASYN...")

    # Prepare data
    feature_names <- setdiff(names(data), c(target_var, "group", "Group", "class", "Class"))
    X <- data[, feature_names, drop = FALSE]
    y <- data[[target_var]]

    # Apply ADASYN
    result <- smotefamily::ADAS(
      X = X,
      target = y,
      K = k
    )

    balanced_data <- result$data
    names(balanced_data)[names(balanced_data) == "class"] <- target_var

    # Report results
    original_counts <- table(data[[target_var]])
    new_counts <- table(balanced_data[[target_var]])

    message("  Original distribution: ", paste(names(original_counts), "=", original_counts, collapse = ", "))
    message("  New distribution:      ", paste(names(new_counts), "=", new_counts, collapse = ", "))

    return(balanced_data)

  }, error = function(e) {
    warning(paste("ADASYN failed:", e$message))
    message("  Falling back to SMOTE")
    return(apply_smote(data, target_var, k = k))
  })
}

################################################################################
# RANDOM SAMPLING METHODS
################################################################################

#' Random oversampling of minority classes
#'
#' @param data Data frame
#' @param target_var Target variable name
#' @param ratio Target ratio of minority to majority (default: 1.0 for perfect balance)
#' @return Balanced dataset
apply_random_oversampling <- function(data, target_var = "group", ratio = 1.0) {

  tryCatch({

    message("Applying random oversampling...")

    class_counts <- table(data[[target_var]])
    max_count <- max(class_counts)
    target_count <- round(max_count * ratio)

    balanced_data <- data

    for (class_name in names(class_counts)) {
      class_data <- data[data[[target_var]] == class_name, ]
      current_count <- nrow(class_data)

      if (current_count < target_count) {
        # Oversample this class
        n_samples_needed <- target_count - current_count
        sampled_indices <- sample(1:current_count, n_samples_needed, replace = TRUE)
        oversampled_data <- class_data[sampled_indices, ]
        balanced_data <- rbind(balanced_data, oversampled_data)
      }
    }

    # Report results
    original_counts <- table(data[[target_var]])
    new_counts <- table(balanced_data[[target_var]])

    message("  Original distribution: ", paste(names(original_counts), "=", original_counts, collapse = ", "))
    message("  New distribution:      ", paste(names(new_counts), "=", new_counts, collapse = ", "))

    return(balanced_data)

  }, error = function(e) {
    warning(paste("Random oversampling failed:", e$message))
    return(data)
  })
}

#' Random undersampling of majority classes
#'
#' @param data Data frame
#' @param target_var Target variable name
#' @param ratio Target ratio of majority to minority (default: 1.0 for perfect balance)
#' @return Balanced dataset
apply_random_undersampling <- function(data, target_var = "group", ratio = 1.0) {

  tryCatch({

    message("Applying random undersampling...")

    class_counts <- table(data[[target_var]])
    min_count <- min(class_counts)
    target_count <- round(min_count / ratio)

    balanced_data <- data.frame()

    for (class_name in names(class_counts)) {
      class_data <- data[data[[target_var]] == class_name, ]
      current_count <- nrow(class_data)

      if (current_count > target_count) {
        # Undersample this class
        sampled_indices <- sample(1:current_count, target_count, replace = FALSE)
        undersampled_data <- class_data[sampled_indices, ]
        balanced_data <- rbind(balanced_data, undersampled_data)
      } else {
        # Keep all samples
        balanced_data <- rbind(balanced_data, class_data)
      }
    }

    # Report results
    original_counts <- table(data[[target_var]])
    new_counts <- table(balanced_data[[target_var]])

    message("  Original distribution: ", paste(names(original_counts), "=", original_counts, collapse = ", "))
    message("  New distribution:      ", paste(names(new_counts), "=", new_counts, collapse = ", "))

    return(balanced_data)

  }, error = function(e) {
    warning(paste("Random undersampling failed:", e$message))
    return(data)
  })
}

################################################################################
# HYBRID METHODS
################################################################################

#' Apply hybrid sampling (SMOTE + undersampling)
#'
#' @param data Data frame
#' @param target_var Target variable name
#' @param smote_ratio SMOTE oversampling ratio (default: 1.5)
#' @param undersample_ratio Undersampling ratio (default: 1.2)
#' @return Balanced dataset
apply_hybrid_sampling <- function(data, target_var = "group",
                                 smote_ratio = 1.5, undersample_ratio = 1.2) {

  tryCatch({

    message("Applying hybrid sampling (SMOTE + undersampling)...")

    # Step 1: Apply SMOTE
    smote_data <- apply_smote(data, target_var, perc_over = (smote_ratio - 1) * 100)

    # Step 2: Apply undersampling
    balanced_data <- apply_random_undersampling(smote_data, target_var, ratio = 1.0 / undersample_ratio)

    return(balanced_data)

  }, error = function(e) {
    warning(paste("Hybrid sampling failed:", e$message))
    return(data)
  })
}

################################################################################
# UNIFIED INTERFACE WITH USER CHOICE
################################################################################

#' Balance dataset with user-selected method and target sets
#'
#' @param data Data frame
#' @param target_var Target variable name
#' @param method Balancing method: "smote", "adasyn", "oversample", "undersample", "hybrid", "none"
#' @param apply_to Which sets to balance: "train", "validation", "both"
#' @param train_indices Indices of training set (if apply_to includes validation)
#' @param test_indices Indices of validation/test set (if apply_to includes validation)
#' @param auto_detect Automatically detect and recommend method (default: TRUE)
#' @return List with balanced training and/or validation sets
balance_dataset <- function(data, target_var = "group", method = "smote",
                           apply_to = "train", train_indices = NULL, test_indices = NULL,
                           auto_detect = TRUE) {

  message("\n=== Class Imbalance Handling ===")

  # Detect imbalance
  imbalance_info <- detect_class_imbalance(data, target_var)

  if (!is.null(imbalance_info)) {
    message("Imbalance detected:")
    message("  Severity: ", imbalance_info$severity)
    message("  Ratio: ", round(imbalance_info$imbalance_ratio, 2), ":1")
    message("  Majority class: ", imbalance_info$majority_class, " (", imbalance_info$class_counts[imbalance_info$majority_class], " samples)")
    message("  Minority class: ", imbalance_info$minority_class, " (", imbalance_info$class_counts[imbalance_info$minority_class], " samples)")
    message("  Recommendation: ", imbalance_info$recommendation)
  }

  # Auto-select method if needed
  if (auto_detect && !is.null(imbalance_info) && method == "auto") {
    if (imbalance_info$severity == "severe") {
      method <- "hybrid"
    } else if (imbalance_info$severity == "high") {
      method <- "smote"
    } else if (imbalance_info$severity == "moderate") {
      method <- "oversample"
    } else {
      method <- "none"
    }
    message("\nAuto-selected method: ", method)
  }

  if (method == "none" || (!imbalance_info$is_imbalanced && !auto_detect)) {
    message("No balancing applied")
    return(list(
      train = if(!is.null(train_indices)) data[train_indices, ] else data,
      test = if(!is.null(test_indices)) data[test_indices, ] else NULL,
      method = "none"
    ))
  }

  message("\nApplying method: ", method)
  message("Target sets: ", apply_to)

  result <- list(method = method, apply_to = apply_to)

  # Apply to training set
  if (apply_to %in% c("train", "both")) {

    train_data <- if (!is.null(train_indices)) data[train_indices, ] else data

    balanced_train <- switch(
      method,
      "smote" = apply_smote(train_data, target_var),
      "adasyn" = apply_adasyn(train_data, target_var),
      "oversample" = apply_random_oversampling(train_data, target_var),
      "undersample" = apply_random_undersampling(train_data, target_var),
      "hybrid" = apply_hybrid_sampling(train_data, target_var),
      train_data  # default: no change
    )

    result$train <- balanced_train
  } else {
    result$train <- if (!is.null(train_indices)) data[train_indices, ] else data
  }

  # Apply to validation set
  if (apply_to %in% c("validation", "both") && !is.null(test_indices)) {

    test_data <- data[test_indices, ]

    balanced_test <- switch(
      method,
      "smote" = apply_smote(test_data, target_var),
      "adasyn" = apply_adasyn(test_data, target_var),
      "oversample" = apply_random_oversampling(test_data, target_var),
      "undersample" = apply_random_undersampling(test_data, target_var),
      "hybrid" = apply_hybrid_sampling(test_data, target_var),
      test_data  # default: no change
    )

    result$test <- balanced_test
  } else {
    result$test <- if (!is.null(test_indices)) data[test_indices, ] else NULL
  }

  message("\n=== Balancing Complete ===\n")

  return(result)
}

################################################################################
# VISUALIZATION
################################################################################

#' Create visualization of class distribution before and after balancing
#'
#' @param original_data Original dataset
#' @param balanced_data Balanced dataset
#' @param target_var Target variable name
#' @return ggplot object (if ggplot2 available)
plot_class_distribution <- function(original_data, balanced_data, target_var = "group") {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    message("Class distribution visualization requires 'ggplot2' package")
    return(NULL)
  }

  tryCatch({

    # Prepare data
    original_counts <- as.data.frame(table(original_data[[target_var]]))
    names(original_counts) <- c("Class", "Count")
    original_counts$Dataset <- "Original"

    balanced_counts <- as.data.frame(table(balanced_data[[target_var]]))
    names(balanced_counts) <- c("Class", "Count")
    balanced_counts$Dataset <- "Balanced"

    plot_data <- rbind(original_counts, balanced_counts)

    # Create plot
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Class, y = Count, fill = Dataset)) +
      ggplot2::geom_bar(stat = "identity", position = "dodge") +
      ggplot2::labs(
        title = "Class Distribution: Original vs Balanced",
        x = "Class",
        y = "Number of Samples",
        fill = "Dataset"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::scale_fill_manual(values = c("Original" = "#e74c3c", "Balanced" = "#2ecc71"))

    return(p)

  }, error = function(e) {
    warning(paste("Visualization failed:", e$message))
    return(NULL)
  })
}

################################################################################
# EXPORT HELPERS
################################################################################

#' Generate summary report of balancing operation
#'
#' @param balance_result Result from balance_dataset()
#' @param output_file Output file path (optional)
generate_balance_report <- function(balance_result, output_file = NULL) {

  report <- paste0("
# Class Balancing Report

## Method Applied
**Balancing Method:** ", balance_result$method, "
**Applied To:** ", balance_result$apply_to, "

## Training Set Distribution
")

  if (!is.null(balance_result$train)) {
    train_dist <- table(balance_result$train$group)
    report <- paste0(report, "\n")
    for (class_name in names(train_dist)) {
      report <- paste0(report, "- ", class_name, ": ", train_dist[class_name], " samples\n")
    }
  }

  if (!is.null(balance_result$test)) {
    report <- paste0(report, "\n## Validation Set Distribution\n\n")
    test_dist <- table(balance_result$test$group)
    for (class_name in names(test_dist)) {
      report <- paste0(report, "- ", class_name, ": ", test_dist[class_name], " samples\n")
    }
  }

  report <- paste0(report, "
## Notes
- SMOTE creates synthetic examples by interpolating between existing minority class samples
- ADASYN adapts the number of synthetic samples based on local density
- Random oversampling duplicates minority class samples
- Random undersampling removes majority class samples
- Hybrid combines SMOTE with undersampling for severe imbalance

**Generated:** ", Sys.time(), "
")

  if (!is.null(output_file)) {
    writeLines(report, output_file)
    message("Balance report saved to: ", output_file)
  }

  return(report)
}

################################################################################
# EXPORT
################################################################################

message("✓ SMOTE & imbalance handling module loaded")
message("  Available methods: SMOTE, ADASYN, Random Over/Under-sampling, Hybrid")
message("  User can choose: apply to train, validation, or both")
