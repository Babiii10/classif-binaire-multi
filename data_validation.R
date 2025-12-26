##########################
# Data Validation System
# Automatic detection of data quality issues
##########################

##########################
# 1. Class Imbalance Detection
##########################

detect_class_imbalance <- function(data, threshold_ratio = 2) {
  class_counts <- table(data[,1])
  n_classes <- length(class_counts)

  min_count <- min(class_counts)
  max_count <- max(class_counts)
  ratio <- max_count / min_count

  severity <- if(ratio > 10) {
    "critical"
  } else if(ratio > 5) {
    "severe"
  } else if(ratio > threshold_ratio) {
    "moderate"
  } else {
    "none"
  }

  suggestions <- if(severity != "none") {
    c(
      "Utiliser SMOTE (Synthetic Minority Over-sampling)",
      "Appliquer class weights dans les modèles",
      "Sous-échantillonner la classe majoritaire",
      "Sur-échantillonner la classe minoritaire",
      "Utiliser métriques équilibrées (F1, balanced accuracy)"
    )
  } else {
    character(0)
  }

  list(
    severity = severity,
    ratio = round(ratio, 2),
    class_counts = as.list(class_counts),
    minority_class = names(class_counts)[which.min(class_counts)],
    majority_class = names(class_counts)[which.max(class_counts)],
    suggestions = suggestions
  )
}

##########################
# 2. Outlier Detection
##########################

detect_outliers <- function(data, method = "iqr", threshold = 3) {
  # Remove first column (class labels)
  if(is.data.frame(data)) {
    numeric_data <- as.matrix(data[,-1])
  } else {
    numeric_data <- data
  }

  outlier_info <- list()

  if(method == "iqr") {
    # IQR method (Interquartile Range)
    for(j in 1:ncol(numeric_data)) {
      col_data <- numeric_data[,j]
      col_data <- col_data[!is.na(col_data)]

      Q1 <- quantile(col_data, 0.25)
      Q3 <- quantile(col_data, 0.75)
      IQR <- Q3 - Q1

      lower_bound <- Q1 - 1.5 * IQR
      upper_bound <- Q3 + 1.5 * IQR

      outliers <- col_data < lower_bound | col_data > upper_bound
      outlier_pct <- sum(outliers) / length(col_data)

      if(outlier_pct > 0.05) {  # More than 5% outliers
        outlier_info[[colnames(numeric_data)[j]]] <- list(
          percentage = round(outlier_pct * 100, 2),
          n_outliers = sum(outliers),
          bounds = c(lower = lower_bound, upper = upper_bound)
        )
      }
    }
  } else if(method == "zscore") {
    # Z-score method
    for(j in 1:ncol(numeric_data)) {
      col_data <- numeric_data[,j]
      col_data <- col_data[!is.na(col_data)]

      z_scores <- abs((col_data - mean(col_data)) / sd(col_data))
      outliers <- z_scores > threshold
      outlier_pct <- sum(outliers) / length(col_data)

      if(outlier_pct > 0.05) {
        outlier_info[[colnames(numeric_data)[j]]] <- list(
          percentage = round(outlier_pct * 100, 2),
          n_outliers = sum(outliers),
          threshold = threshold
        )
      }
    }
  }

  total_outlier_pct <- if(length(outlier_info) > 0) {
    mean(sapply(outlier_info, function(x) x$percentage / 100))
  } else {
    0
  }

  severity <- if(total_outlier_pct > 0.2) {
    "severe"
  } else if(total_outlier_pct > 0.1) {
    "moderate"
  } else if(total_outlier_pct > 0.05) {
    "minor"
  } else {
    "none"
  }

  suggestions <- if(severity != "none") {
    c(
      "Vérifier manuellement les valeurs extrêmes",
      "Appliquer transformation log pour réduire l'asymétrie",
      "Utiliser méthodes robustes (Random Forest, médiane)",
      "Considérer winsorisation (clip à percentiles)",
      "Exclure outliers si erreurs de mesure"
    )
  } else {
    character(0)
  }

  list(
    severity = severity,
    overall_percentage = round(total_outlier_pct * 100, 2),
    n_variables_affected = length(outlier_info),
    details = outlier_info,
    suggestions = suggestions
  )
}

##########################
# 3. Constant/Near-Constant Variables
##########################

detect_constant_variables <- function(data, variance_threshold = 1e-10) {
  if(is.data.frame(data)) {
    numeric_data <- as.matrix(data[,-1])
  } else {
    numeric_data <- data
  }

  variances <- apply(numeric_data, 2, var, na.rm = TRUE)
  constant_vars <- names(variances)[variances < variance_threshold | is.na(variances)]

  near_constant <- names(variances)[variances < 0.01 & variances >= variance_threshold]

  list(
    constant_variables = constant_vars,
    near_constant_variables = near_constant,
    n_constant = length(constant_vars),
    n_near_constant = length(near_constant),
    suggestion = if(length(constant_vars) > 0) {
      "Supprimer les variables constantes (pas d'information)"
    } else {
      NULL
    }
  )
}

##########################
# 4. Perfect Correlations
##########################

detect_perfect_correlations <- function(data, threshold = 0.99) {
  if(is.data.frame(data)) {
    numeric_data <- as.matrix(data[,-1])
  } else {
    numeric_data <- data
  }

  # Calculate correlation matrix
  cor_matrix <- cor(numeric_data, use = "pairwise.complete.obs")

  # Find pairs with correlation > threshold
  perfect_pairs <- which(abs(cor_matrix) > threshold & abs(cor_matrix) < 1, arr.ind = TRUE)

  # Remove duplicates (upper triangle only)
  perfect_pairs <- perfect_pairs[perfect_pairs[,1] < perfect_pairs[,2], , drop = FALSE]

  if(nrow(perfect_pairs) > 0) {
    pairs_df <- data.frame(
      var1 = colnames(numeric_data)[perfect_pairs[,1]],
      var2 = colnames(numeric_data)[perfect_pairs[,2]],
      correlation = sapply(1:nrow(perfect_pairs), function(i) {
        cor_matrix[perfect_pairs[i,1], perfect_pairs[i,2]]
      })
    )
  } else {
    pairs_df <- data.frame()
  }

  list(
    n_pairs = nrow(perfect_pairs),
    pairs = pairs_df,
    suggestion = if(nrow(perfect_pairs) > 0) {
      "Supprimer une variable de chaque paire corrélée (redondance)"
    } else {
      NULL
    }
  )
}

##########################
# 5. Missing Data Analysis
##########################

analyze_missing_data <- function(data) {
  if(is.data.frame(data)) {
    numeric_data <- data[,-1]
  } else {
    numeric_data <- data
  }

  # Overall missing percentage
  total_missing <- sum(is.na(numeric_data)) / (nrow(numeric_data) * ncol(numeric_data))

  # Missing per variable
  missing_per_var <- colSums(is.na(numeric_data)) / nrow(numeric_data)
  high_missing_vars <- names(missing_per_var)[missing_per_var > 0.5]

  # Missing per sample
  missing_per_sample <- rowSums(is.na(numeric_data)) / ncol(numeric_data)
  high_missing_samples <- which(missing_per_sample > 0.5)

  severity <- if(total_missing > 0.3) {
    "severe"
  } else if(total_missing > 0.15) {
    "moderate"
  } else if(total_missing > 0.05) {
    "minor"
  } else {
    "none"
  }

  suggestions <- if(severity != "none") {
    c(
      "Considérer supprimer variables avec >50% manquants",
      "Utiliser imputation PCA ou Random Forest",
      "Vérifier si manquants sont structurés (MNAR vs MAR)",
      "Utiliser modèles robustes aux valeurs manquantes"
    )
  } else {
    character(0)
  }

  list(
    severity = severity,
    total_percentage = round(total_missing * 100, 2),
    n_high_missing_vars = length(high_missing_vars),
    high_missing_vars = high_missing_vars,
    n_high_missing_samples = length(high_missing_samples),
    suggestions = suggestions
  )
}

##########################
# 6. Sample Size Adequacy
##########################

check_sample_size <- function(data, min_samples_per_class = 20,
                              min_samples_per_feature = 5) {
  n_samples <- nrow(data)
  n_features <- ncol(data) - 1
  class_counts <- table(data[,1])

  # Check minimum per class
  min_class_size <- min(class_counts)
  adequate_class_size <- min_class_size >= min_samples_per_class

  # Check samples to features ratio
  ratio <- n_samples / n_features
  adequate_ratio <- ratio >= min_samples_per_feature

  severity <- if(!adequate_class_size || !adequate_ratio) {
    "warning"
  } else if(min_class_size < 50 || ratio < 10) {
    "caution"
  } else {
    "adequate"
  }

  suggestions <- c()
  if(!adequate_class_size) {
    suggestions <- c(suggestions,
                     "Classe minoritaire insuffisante (<20 échantillons)",
                     "Collecter plus de données ou réduire nombre de classes")
  }
  if(!adequate_ratio) {
    suggestions <- c(suggestions,
                     sprintf("Ratio échantillons/features trop faible (%.1f)", ratio),
                     "Réduire nombre de features (feature selection)",
                     "Augmenter taille de l'échantillon")
  }

  list(
    severity = severity,
    n_samples = n_samples,
    n_features = n_features,
    ratio = round(ratio, 2),
    min_class_size = min_class_size,
    class_counts = as.list(class_counts),
    adequate = adequate_class_size && adequate_ratio,
    suggestions = suggestions
  )
}

##########################
# Master Validation Function
##########################

validate_data_quality <- function(data, verbose = TRUE) {

  if(verbose) cat("===== Validation de la Qualité des Données =====\n\n")

  validation_results <- list()

  # 1. Class imbalance
  if(verbose) cat("1. Vérification de l'équilibre des classes...\n")
  validation_results$imbalance <- detect_class_imbalance(data)
  if(verbose && validation_results$imbalance$severity != "none") {
    cat(sprintf("   ⚠️  Déséquilibre détecté (ratio %.2f:1)\n",
                validation_results$imbalance$ratio))
  }

  # 2. Outliers
  if(verbose) cat("2. Détection des valeurs aberrantes...\n")
  validation_results$outliers <- detect_outliers(data)
  if(verbose && validation_results$outliers$severity != "none") {
    cat(sprintf("   ⚠️  %.2f%% de valeurs aberrantes dans %d variables\n",
                validation_results$outliers$overall_percentage,
                validation_results$outliers$n_variables_affected))
  }

  # 3. Constant variables
  if(verbose) cat("3. Détection des variables constantes...\n")
  validation_results$constant_vars <- detect_constant_variables(data)
  if(verbose && validation_results$constant_vars$n_constant > 0) {
    cat(sprintf("   ⚠️  %d variables constantes détectées\n",
                validation_results$constant_vars$n_constant))
  }

  # 4. Perfect correlations
  if(verbose) cat("4. Détection des corrélations parfaites...\n")
  validation_results$correlations <- detect_perfect_correlations(data)
  if(verbose && validation_results$correlations$n_pairs > 0) {
    cat(sprintf("   ⚠️  %d paires de variables fortement corrélées\n",
                validation_results$correlations$n_pairs))
  }

  # 5. Missing data
  if(verbose) cat("5. Analyse des données manquantes...\n")
  validation_results$missing <- analyze_missing_data(data)
  if(verbose && validation_results$missing$severity != "none") {
    cat(sprintf("   ⚠️  %.2f%% de valeurs manquantes au total\n",
                validation_results$missing$total_percentage))
  }

  # 6. Sample size
  if(verbose) cat("6. Vérification de la taille d'échantillon...\n")
  validation_results$sample_size <- check_sample_size(data)
  if(verbose && validation_results$sample_size$severity != "adequate") {
    cat(sprintf("   ⚠️  Taille d'échantillon limite (ratio: %.2f)\n",
                validation_results$sample_size$ratio))
  }

  # Overall assessment
  critical_issues <- c()
  warnings <- c()

  if(validation_results$imbalance$severity %in% c("critical", "severe")) {
    critical_issues <- c(critical_issues, "Déséquilibre de classes sévère")
  }
  if(validation_results$constant_vars$n_constant > 0) {
    critical_issues <- c(critical_issues, "Variables constantes présentes")
  }
  if(validation_results$sample_size$severity == "warning") {
    critical_issues <- c(critical_issues, "Taille d'échantillon insuffisante")
  }

  if(validation_results$outliers$severity %in% c("severe", "moderate")) {
    warnings <- c(warnings, "Valeurs aberrantes nombreuses")
  }
  if(validation_results$missing$severity %in% c("severe", "moderate")) {
    warnings <- c(warnings, "Taux de données manquantes élevé")
  }
  if(validation_results$correlations$n_pairs > 0) {
    warnings <- c(warnings, "Variables redondantes détectées")
  }

  validation_results$summary <- list(
    overall_status = if(length(critical_issues) > 0) {
      "critical"
    } else if(length(warnings) > 0) {
      "warning"
    } else {
      "good"
    },
    critical_issues = critical_issues,
    warnings = warnings,
    n_issues = length(critical_issues) + length(warnings)
  )

  if(verbose) {
    cat("\n===== Résumé de la Validation =====\n")
    if(validation_results$summary$overall_status == "good") {
      cat("✅ Qualité des données : BONNE\n")
      cat("Aucun problème majeur détecté.\n")
    } else {
      cat(sprintf("⚠️  Statut : %s\n", toupper(validation_results$summary$overall_status)))
      if(length(critical_issues) > 0) {
        cat("\n🔴 Problèmes critiques :\n")
        for(issue in critical_issues) {
          cat(sprintf("   - %s\n", issue))
        }
      }
      if(length(warnings) > 0) {
        cat("\n🟡 Avertissements :\n")
        for(warn in warnings) {
          cat(sprintf("   - %s\n", warn))
        }
      }
    }
    cat("\n=====================================\n")
  }

  return(validation_results)
}

##########################
# Generate Validation Report
##########################

generate_validation_report_html <- function(validation_results, output_file = "validation_report.html") {

  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Validation des Données</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; border-left: 4px solid #007bff; padding-left: 10px; }
        .status-good { background-color: #d4edda; color: #155724; padding: 15px; border-radius: 5px; border: 1px solid #c3e6cb; }
        .status-warning { background-color: #fff3cd; color: #856404; padding: 15px; border-radius: 5px; border: 1px solid #ffeeba; }
        .status-critical { background-color: #f8d7da; color: #721c24; padding: 15px; border-radius: 5px; border: 1px solid #f5c6cb; }
        .metric { background-color: white; padding: 15px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-title { font-weight: bold; color: #007bff; margin-bottom: 10px; }
        .suggestions { background-color: #e7f3ff; padding: 10px; margin-top: 10px; border-left: 3px solid #007bff; }
        ul { margin: 5px 0; }
        table { width: 100%%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #007bff; color: white; }
    </style>
</head>
<body>
    <h1>📊 Rapport de Validation des Données</h1>
    <p><strong>Généré le :</strong> %s</p>

    <div class="status-%s">
        <h3>Statut Global : %s</h3>
        %s
    </div>

    <h2>1. Équilibre des Classes</h2>
    <div class="metric">
        <div class="metric-title">Déséquilibre : %s (Ratio: %.2f:1)</div>
        <p><strong>Distribution :</strong></p>
        <ul>%s</ul>
        %s
    </div>

    <h2>2. Valeurs Aberrantes</h2>
    <div class="metric">
        <div class="metric-title">Sévérité : %s (%.2f%% au total)</div>
        <p><strong>Variables affectées :</strong> %d</p>
        %s
    </div>

    <h2>3. Variables Constantes/Redondantes</h2>
    <div class="metric">
        <div class="metric-title">Variables constantes : %d | Fortement corrélées : %d paires</div>
        %s
    </div>

    <h2>4. Données Manquantes</h2>
    <div class="metric">
        <div class="metric-title">Sévérité : %s (%.2f%% au total)</div>
        <p><strong>Variables avec >50%% manquants :</strong> %d</p>
        %s
    </div>

    <h2>5. Taille d''Échantillon</h2>
    <div class="metric">
        <div class="metric-title">Échantillons : %d | Features : %d | Ratio : %.2f</div>
        <p><strong>Classe minoritaire :</strong> %d échantillons</p>
        %s
    </div>

</body>
</html>
  ',
  # Parameters
  format(Sys.time(), "%%Y-%%m-%%d %%H:%%M:%%S"),
  validation_results$summary$overall_status,
  toupper(validation_results$summary$overall_status),
  if(length(c(validation_results$summary$critical_issues, validation_results$summary$warnings)) > 0) {
    paste("<ul>",
          paste(sapply(c(validation_results$summary$critical_issues,
                        validation_results$summary$warnings),
                      function(x) paste0("<li>", x, "</li>")), collapse=""),
          "</ul>")
  } else {
    "<p>✅ Aucun problème détecté</p>"
  },

  # Imbalance
  toupper(validation_results$imbalance$severity),
  validation_results$imbalance$ratio,
  paste(sapply(names(validation_results$imbalance$class_counts), function(cls) {
    sprintf("<li>%s: %d échantillons</li>", cls, validation_results$imbalance$class_counts[[cls]])
  }), collapse=""),
  if(length(validation_results$imbalance$suggestions) > 0) {
    paste0('<div class="suggestions"><strong>Suggestions:</strong><ul>',
           paste(sapply(validation_results$imbalance$suggestions, function(x) paste0("<li>", x, "</li>")), collapse=""),
           "</ul></div>")
  } else { "" },

  # Outliers
  toupper(validation_results$outliers$severity),
  validation_results$outliers$overall_percentage,
  validation_results$outliers$n_variables_affected,
  if(length(validation_results$outliers$suggestions) > 0) {
    paste0('<div class="suggestions"><strong>Suggestions:</strong><ul>',
           paste(sapply(validation_results$outliers$suggestions, function(x) paste0("<li>", x, "</li>")), collapse=""),
           "</ul></div>")
  } else { "" },

  # Constant/Correlated
  validation_results$constant_vars$n_constant,
  validation_results$correlations$n_pairs,
  if(validation_results$constant_vars$n_constant > 0 || validation_results$correlations$n_pairs > 0) {
    paste0('<div class="suggestions"><strong>Action requise:</strong><p>',
           if(validation_results$constant_vars$n_constant > 0)
             sprintf("Supprimer %d variables constantes. ", validation_results$constant_vars$n_constant)
           else "",
           if(validation_results$correlations$n_pairs > 0)
             sprintf("Supprimer %d variables redondantes.", validation_results$correlations$n_pairs)
           else "",
           "</p></div>")
  } else { "<p>✅ Pas de variables problématiques</p>" },

  # Missing
  toupper(validation_results$missing$severity),
  validation_results$missing$total_percentage,
  validation_results$missing$n_high_missing_vars,
  if(length(validation_results$missing$suggestions) > 0) {
    paste0('<div class="suggestions"><strong>Suggestions:</strong><ul>',
           paste(sapply(validation_results$missing$suggestions, function(x) paste0("<li>", x, "</li>")), collapse=""),
           "</ul></div>")
  } else { "" },

  # Sample size
  validation_results$sample_size$n_samples,
  validation_results$sample_size$n_features,
  validation_results$sample_size$ratio,
  validation_results$sample_size$min_class_size,
  if(!validation_results$sample_size$adequate) {
    paste0('<div class="suggestions"><strong>Suggestions:</strong><ul>',
           paste(sapply(validation_results$sample_size$suggestions, function(x) paste0("<li>", x, "</li>")), collapse=""),
           "</ul></div>")
  } else { "<p>✅ Taille adéquate</p>" }
  )

  writeLines(html_content, output_file)
  message(sprintf("Rapport de validation généré : %s", output_file))

  return(output_file)
}

message("Data validation system loaded")
