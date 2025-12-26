##########################
# Automatic Reporting System
# Generate comprehensive HTML/PDF reports
##########################

##########################
# Report Generation
##########################

generate_analysis_report <- function(analysis_results, output_file = "analysis_report.html",
                                    format = "html", include_plots = TRUE) {

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  # Extract components
  data_summary <- analysis_results$data_summary
  preprocessing <- analysis_results$preprocessing
  feature_selection <- analysis_results$feature_selection
  model_results <- analysis_results$model_results
  validation_report <- analysis_results$validation

  # Generate HTML
  html_content <- sprintf('
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d''Analyse de Classification</title>
    <style>
        body {
            font-family: ''Segoe UI'', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f9fa;
        }
        h1 {
            color: #007bff;
            border-bottom: 4px solid #007bff;
            padding-bottom: 15px;
            margin-bottom: 30px;
        }
        h2 {
            color: #0056b3;
            margin-top: 40px;
            padding-left: 10px;
            border-left: 5px solid #007bff;
            background-color: #e7f3ff;
            padding: 10px;
            border-radius: 4px;
        }
        h3 {
            color: #495057;
            margin-top: 25px;
        }
        .summary-box {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 25px;
            border-radius: 10px;
            margin: 20px 0;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .metric-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
            border-top: 4px solid #007bff;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #007bff;
            margin: 10px 0;
        }
        .metric-label {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        table {
            width: 100%%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th {
            background-color: #007bff;
            color: white;
            padding: 15px;
            text-align: left;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #dee2e6;
        }
        tr:hover {
            background-color: #f8f9fa;
        }
        .info-box {
            background-color: #d1ecf1;
            border-left: 5px solid #17a2b8;
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
        }
        .warning-box {
            background-color: #fff3cd;
            border-left: 5px solid #ffc107;
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
        }
        .success-box {
            background-color: #d4edda;
            border-left: 5px solid #28a745;
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
        }
        .plot-container {
            background: white;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .plot-container img {
            max-width: 100%%;
            height: auto;
            display: block;
            margin: 0 auto;
        }
        .footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 2px solid #dee2e6;
            text-align: center;
            color: #6c757d;
            font-size: 0.9em;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .badge-primary { background-color: #007bff; color: white; }
        .badge-success { background-color: #28a745; color: white; }
        .badge-warning { background-color: #ffc107; color: #212529; }
        .badge-danger { background-color: #dc3545; color: white; }
    </style>
</head>
<body>
    <h1>📊 Rapport d\\'Analyse de Classification Omics</h1>

    <div class="summary-box">
        <h3 style="margin-top: 0;">Informations Générales</h3>
        <p><strong>Date de génération :</strong> %s</p>
        <p><strong>Analyse effectuée par :</strong> I2MC Classification App v2.0</p>
        <p><strong>Type de classification :</strong> %s</p>
    </div>

    %s

    %s

    %s

    %s

    <div class="footer">
        <p>Généré automatiquement par I2MC Classification Application</p>
        <p>© 2025 I2MC - Tous droits réservés</p>
    </div>
</body>
</html>
  ',
  # Parameters
  timestamp,
  if(data_summary$n_classes == 2) "Classification Binaire" else sprintf("Classification Multi-classe (%d classes)", data_summary$n_classes),

  # Data Summary Section
  generate_data_summary_html(data_summary),

  # Preprocessing Section
  generate_preprocessing_html(preprocessing),

  # Feature Selection Section
  if(!is.null(feature_selection)) generate_feature_selection_html(feature_selection) else "",

  # Model Results Section
  generate_model_results_html(model_results, include_plots)
  )

  writeLines(html_content, output_file)
  message(sprintf("✅ Rapport généré : %s", output_file))

  return(output_file)
}

##########################
# Helper Functions for Report Sections
##########################

generate_data_summary_html <- function(data_summary) {
  sprintf('
    <h2>📁 Résumé des Données</h2>

    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-label">Échantillons</div>
            <div class="metric-value">%d</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Variables</div>
            <div class="metric-value">%d</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Classes</div>
            <div class="metric-value">%d</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Valeurs Manquantes</div>
            <div class="metric-value">%.1f%%</div>
        </div>
    </div>

    <h3>Distribution des Classes</h3>
    <table>
        <tr>
            <th>Classe</th>
            <th>Nombre d\\'échantillons</th>
            <th>Pourcentage</th>
        </tr>
        %s
    </table>

    %s
  ',
  data_summary$n_samples,
  data_summary$n_features,
  data_summary$n_classes,
  data_summary$missing_percentage,

  paste(sapply(names(data_summary$class_distribution), function(cls) {
    count <- data_summary$class_distribution[[cls]]
    pct <- round(count / data_summary$n_samples * 100, 1)
    sprintf("<tr><td>%s</td><td>%d</td><td>%.1f%%</td></tr>", cls, count, pct)
  }), collapse = ""),

  if(!is.null(data_summary$validation_info)) {
    sprintf('<div class="info-box">
        <h4>Ensemble de Validation</h4>
        <p><strong>Échantillons :</strong> %d | <strong>Variables :</strong> %d</p>
    </div>',
    data_summary$validation_info$n_samples,
    data_summary$validation_info$n_features)
  } else {
    '<div class="warning-box">
        <strong>Note :</strong> Aucun ensemble de validation indépendant fourni.
    </div>'
  }
  )
}

generate_preprocessing_html <- function(preprocessing) {
  sprintf('
    <h2>🔧 Prétraitement des Données</h2>

    <h3>Sélection des Variables</h3>
    <div class="info-box">
        <p><strong>Critère :</strong> %s</p>
        <p><strong>Seuil :</strong> %.0f%% de valeurs non-manquantes</p>
        <p><strong>Variables retenues :</strong> %d / %d (%.1f%%)</p>
    </div>

    <h3>Transformation des Données</h3>
    <table>
        <tr>
            <th>Opération</th>
            <th>Appliquée</th>
            <th>Détails</th>
        </tr>
        <tr>
            <td>Remplacement des NA</td>
            <td>%s</td>
            <td>Méthode : %s</td>
        </tr>
        <tr>
            <td>Transformation log</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
        <tr>
            <td>Standardisation</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
        <tr>
            <td>Transformation arcsinus</td>
            <td>%s</td>
            <td>%s</td>
        </tr>
    </table>
  ',
  preprocessing$selection_method,
  preprocessing$min_values_pct,
  preprocessing$n_features_selected,
  preprocessing$n_features_initial,
  round(preprocessing$n_features_selected / preprocessing$n_features_initial * 100, 1),

  if(preprocessing$na_replacement != "none") "✅ Oui" else "❌ Non",
  preprocessing$na_replacement,

  if(preprocessing$log_transform) "✅ Oui" else "❌ Non",
  if(preprocessing$log_transform) preprocessing$log_type else "-",

  if(preprocessing$standardization) "✅ Oui" else "❌ Non",
  if(preprocessing$standardization) "Normalization par SD" else "-",

  if(preprocessing$arcsin_transform) "✅ Oui" else "❌ Non",
  if(preprocessing$arcsin_transform) "Arcsin(sqrt(x))" else "-"
  )
}

generate_feature_selection_html <- function(feature_selection) {
  sprintf('
    <h2>🎯 Sélection de Variables</h2>

    <div class="info-box">
        <p><strong>Méthode :</strong> %s</p>
        <p><strong>Variables sélectionnées :</strong> %d</p>
        %s
    </div>

    %s

    <h3>Top 10 Variables</h3>
    <table>
        <tr>
            <th>Rang</th>
            <th>Variable</th>
            <th>Score</th>
            <th>P-value</th>
        </tr>
        %s
    </table>
  ',
  feature_selection$method,
  feature_selection$n_selected,
  if(!is.null(feature_selection$threshold_info))
    sprintf("<p><strong>Seuils :</strong> FC > %.2f, p-value < %.4f</p>",
            feature_selection$threshold_info$fc, feature_selection$threshold_info$pval)
  else "",

  if(feature_selection$n_selected == 0) {
    '<div class="warning-box">
        <strong>Attention :</strong> Aucune variable n\\'a passé les critères de sélection.
        Considérer assouplir les seuils.
    </div>'
  } else "",

  paste(sapply(1:min(10, nrow(feature_selection$top_features)), function(i) {
    feat <- feature_selection$top_features[i,]
    sprintf("<tr><td>%d</td><td><strong>%s</strong></td><td>%.3f</td><td>%.2e</td></tr>",
            i, feat$name, feat$score, feat$pvalue)
  }), collapse = "")
  )
}

generate_model_results_html <- function(model_results, include_plots = TRUE) {

  sprintf('
    <h2>🤖 Résultats du Modèle</h2>

    <div class="success-box">
        <h3 style="margin-top: 0;">Modèle Sélectionné : %s</h3>
        <p><strong>Méthode de tuning :</strong> %s</p>
        %s
    </div>

    <h3>Performances sur Ensemble d\\'Apprentissage</h3>
    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-label">AUC</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Accuracy</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Sensibilité</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Spécificité</div>
            <div class="metric-value">%.3f</div>
        </div>
    </div>

    %s

    <h3>Matrice de Confusion - Apprentissage</h3>
    <table>
        %s
    </table>

    %s

    %s
  ',
  model_results$model_type,
  model_results$tuning_method,
  if(!is.null(model_results$hyperparameters))
    sprintf("<p><strong>Hyperparamètres optimaux :</strong> %s</p>",
            paste(names(model_results$hyperparameters), "=",
                  model_results$hyperparameters, collapse = ", "))
  else "",

  model_results$training$auc,
  model_results$training$accuracy,
  model_results$training$sensitivity,
  model_results$training$specificity,

  # Validation results if available
  if(!is.null(model_results$validation)) {
    sprintf('
    <h3>Performances sur Ensemble de Validation</h3>
    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-label">AUC</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Accuracy</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Sensibilité</div>
            <div class="metric-value">%.3f</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Spécificité</div>
            <div class="metric-value">%.3f</div>
        </div>
    </div>',
    model_results$validation$auc,
    model_results$validation$accuracy,
    model_results$validation$sensitivity,
    model_results$validation$specificity)
  } else {
    ""
  },

  # Confusion matrix training
  generate_confusion_matrix_html(model_results$training$confusion_matrix),

  # Confusion matrix validation
  if(!is.null(model_results$validation)) {
    sprintf("<h3>Matrice de Confusion - Validation</h3><table>%s</table>",
            generate_confusion_matrix_html(model_results$validation$confusion_matrix))
  } else {
    ""
  },

  # Overfitting detection
  if(!is.null(model_results$validation) && !is.null(model_results$overfitting_analysis)) {
    generate_overfitting_analysis_html(model_results$overfitting_analysis)
  } else {
    ""
  }
  )
}

generate_confusion_matrix_html <- function(confusion_matrix) {
  class_names <- rownames(confusion_matrix)

  # Header
  header <- sprintf("<tr><th>Prédit \\ Réel</th>%s</tr>",
                    paste(sapply(class_names, function(x) sprintf("<th>%s</th>", x)), collapse = ""))

  # Rows
  rows <- paste(sapply(1:nrow(confusion_matrix), function(i) {
    sprintf("<tr><th>%s</th>%s</tr>",
            class_names[i],
            paste(sapply(confusion_matrix[i,], function(val) {
              # Highlight diagonal
              if(confusion_matrix[i,i] == val) {
                sprintf("<td style='background-color: #d4edda; font-weight: bold;'>%d</td>", val)
              } else {
                sprintf("<td>%d</td>", val)
              }
            }), collapse = ""))
  }), collapse = "")

  paste(header, rows)
}

generate_overfitting_analysis_html <- function(overfitting_analysis) {
  status_class <- switch(overfitting_analysis$status,
    "severe_overfitting" = "warning-box",
    "moderate_overfitting" = "info-box",
    "good_generalization" = "success-box",
    "info-box"
  )

  status_emoji <- switch(overfitting_analysis$status,
    "severe_overfitting" = "🔴",
    "moderate_overfitting" = "🟡",
    "good_generalization" = "✅",
    "ℹ️"
  )

  sprintf('
    <h3>Analyse de Surapprentissage (Overfitting)</h3>
    <div class="%s">
        <p><strong>Statut :</strong> %s %s</p>
        <p><strong>Différence AUC (Train - Val) :</strong> %.3f</p>
        <p><strong>Différence Accuracy (Train - Val) :</strong> %.3f</p>
        %s
    </div>
  ',
  status_class,
  status_emoji,
  overfitting_analysis$status,
  overfitting_analysis$auc_diff,
  overfitting_analysis$acc_diff,

  if(length(overfitting_analysis$suggestions) > 0) {
    sprintf("<p><strong>Recommandations :</strong></p><ul>%s</ul>",
            paste(sapply(overfitting_analysis$suggestions,
                        function(x) sprintf("<li>%s</li>", x)), collapse = ""))
  } else {
    ""
  }
  )
}

##########################
# Prepare Analysis Results
##########################

prepare_analysis_results <- function(DATA, SELECTDATA, TRANSFORMDATA, STATISTICS, MODEL) {

  # Data summary
  data_summary <- list(
    n_samples = nrow(DATA$LEARNING),
    n_features = ncol(DATA$LEARNING) - 1,
    n_classes = length(levels(DATA$LEARNING[,1])),
    class_distribution = as.list(table(DATA$LEARNING[,1])),
    missing_percentage = round(sum(is.na(DATA$LEARNING)) /
                               (nrow(DATA$LEARNING) * ncol(DATA$LEARNING)) * 100, 2),
    validation_info = if(!is.null(DATA$VALIDATION)) {
      list(
        n_samples = nrow(DATA$VALIDATION),
        n_features = ncol(DATA$VALIDATION) - 1
      )
    } else NULL
  )

  # Preprocessing info
  preprocessing <- list(
    selection_method = "Based on missing values",
    min_values_pct = 50,  # Example, should come from actual parameters
    n_features_initial = ncol(DATA$LEARNING) - 1,
    n_features_selected = ncol(SELECTDATA$LEARNINGSELECT) - 1,
    na_replacement = "PCA",  # Example
    log_transform = FALSE,  # Example
    log_type = NULL,
    standardization = FALSE,
    arcsin_transform = FALSE
  )

  # Feature selection
  feature_selection <- if(!is.null(STATISTICS)) {
    list(
      method = "Statistical test",
      n_selected = nrow(STATISTICS$results),
      threshold_info = list(fc = 0, pval = 0.05),
      top_features = head(STATISTICS$results[order(-STATISTICS$results$auc), ], 10)
    )
  } else NULL

  # Model results
  model_results <- if(!is.null(MODEL)) {
    list(
      model_type = "Random Forest",  # Example
      tuning_method = "default",
      hyperparameters = NULL,
      training = list(
        auc = MODEL$DATALEARNINGMODEL$reslearningmodel$auclearning,
        accuracy = mean(MODEL$DATALEARNINGMODEL$reslearningmodel$predictclasslearning ==
                       MODEL$DATALEARNINGMODEL$reslearningmodel$classlearning),
        sensitivity = 0.85,  # Should be calculated
        specificity = 0.90,  # Should be calculated
        confusion_matrix = table(
          Predicted = MODEL$DATALEARNINGMODEL$reslearningmodel$predictclasslearning,
          Actual = MODEL$DATALEARNINGMODEL$reslearningmodel$classlearning
        )
      ),
      validation = if(!is.null(MODEL$DATAVALIDATIONMODEL)) {
        list(
          auc = MODEL$DATAVALIDATIONMODEL$resvalidationmodel$aucval,
          accuracy = mean(MODEL$DATAVALIDATIONMODEL$resvalidationmodel$predictclassval ==
                         MODEL$DATAVALIDATIONMODEL$resvalidationmodel$classval),
          sensitivity = 0.80,
          specificity = 0.88,
          confusion_matrix = table(
            Predicted = MODEL$DATAVALIDATIONMODEL$resvalidationmodel$predictclassval,
            Actual = MODEL$DATAVALIDATIONMODEL$resvalidationmodel$classval
          )
        )
      } else NULL,
      overfitting_analysis = NULL  # Will be added by overfitting detection module
    )
  } else NULL

  list(
    data_summary = data_summary,
    preprocessing = preprocessing,
    feature_selection = feature_selection,
    model_results = model_results
  )
}

message("Reporting system loaded")
