##########################
# UI Wizard System
# Simplified step-by-step interface
##########################

##########################
# Wizard Steps Definition
##########################

WIZARD_STEPS <- list(
  list(
    id = 1,
    name = "import",
    title = "📁 Import de Données",
    description = "Charger vos fichiers de données",
    icon = "upload"
  ),
  list(
    id = 2,
    name = "validate",
    title = "✓ Validation",
    description = "Vérifier la qualité des données",
    icon = "check-circle"
  ),
  list(
    id = 3,
    name = "preprocess",
    title = "🔧 Prétraitement",
    description = "Sélection et transformation",
    icon = "cogs"
  ),
  list(
    id = 4,
    name = "features",
    title = "🎯 Features",
    description = "Sélection de variables",
    icon = "filter"
  ),
  list(
    id = 5,
    name = "model",
    title = "🤖 Modélisation",
    description = "Choix et entraînement du modèle",
    icon = "robot"
  ),
  list(
    id = 6,
    name = "results",
    title = "📊 Résultats",
    description = "Évaluation et export",
    icon = "chart-bar"
  )
)

##########################
# Progress Bar UI
##########################

create_wizard_progress_bar <- function(current_step, total_steps = 6) {

  steps_html <- sapply(1:total_steps, function(i) {
    step <- WIZARD_STEPS[[i]]

    class_status <- if(i < current_step) {
      "completed"
    } else if(i == current_step) {
      "active"
    } else {
      "pending"
    }

    sprintf('
      <div class="wizard-step wizard-step-%s">
        <div class="wizard-step-number">%d</div>
        <div class="wizard-step-title">%s</div>
        <div class="wizard-step-desc">%s</div>
      </div>
    ', class_status, i, step$title, step$description)
  })

  tagList(
    tags$style(HTML("
      .wizard-container {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 20px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        border-radius: 10px;
        margin-bottom: 30px;
      }
      .wizard-step {
        flex: 1;
        text-align: center;
        position: relative;
        padding: 10px;
      }
      .wizard-step:not(:last-child)::after {
        content: '';
        position: absolute;
        right: -50%;
        top: 25px;
        width: 100%;
        height: 3px;
        background-color: rgba(255,255,255,0.3);
      }
      .wizard-step-completed:not(:last-child)::after {
        background-color: #27ae60;
      }
      .wizard-step-active:not(:last-child)::after {
        background: linear-gradient(to right, #27ae60 50%, rgba(255,255,255,0.3) 50%);
      }
      .wizard-step-number {
        width: 50px;
        height: 50px;
        border-radius: 50%;
        background-color: rgba(255,255,255,0.3);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 10px;
        font-size: 20px;
        font-weight: bold;
        position: relative;
        z-index: 1;
      }
      .wizard-step-completed .wizard-step-number {
        background-color: #27ae60;
      }
      .wizard-step-active .wizard-step-number {
        background-color: #3498db;
        box-shadow: 0 0 20px rgba(52, 152, 219, 0.5);
        animation: pulse 2s infinite;
      }
      @keyframes pulse {
        0% { box-shadow: 0 0 20px rgba(52, 152, 219, 0.5); }
        50% { box-shadow: 0 0 30px rgba(52, 152, 219, 0.8); }
        100% { box-shadow: 0 0 20px rgba(52, 152, 219, 0.5); }
      }
      .wizard-step-title {
        color: white;
        font-weight: bold;
        font-size: 14px;
        margin-bottom: 5px;
      }
      .wizard-step-desc {
        color: rgba(255,255,255,0.8);
        font-size: 11px;
      }
      .wizard-step-pending .wizard-step-title,
      .wizard-step-pending .wizard-step-desc {
        color: rgba(255,255,255,0.5);
      }
    ")),
    div(class = "wizard-container",
        HTML(paste(steps_html, collapse = "")))
  )
}

##########################
# Preset Configurations
##########################

PRESET_CONFIGS <- list(
  quick = list(
    name = "⚡ Analyse Rapide",
    description = "Configuration rapide pour exploration initiale",
    time_estimate = "~5 minutes",
    settings = list(
      feature_selection = list(
        method = "Wilcoxon",
        threshold_pv = 0.05,
        threshold_fc = 0
      ),
      model = list(
        type = "randomforest",
        tuning = "default",
        cv_folds = 3
      ),
      preprocessing = list(
        na_method = "zero",
        log_transform = FALSE,
        standardization = FALSE
      )
    )
  ),

  robust = list(
    name = "🎯 Analyse Robuste (Recommandé)",
    description = "Configuration équilibrée qualité/temps",
    time_estimate = "~15-20 minutes",
    settings = list(
      feature_selection = list(
        method = "clustEnet",
        n_clusters = 100,
        n_bootstrap = 500
      ),
      model = list(
        type = "automl",  # Will test multiple models
        tuning = "cv",
        cv_folds = 5
      ),
      preprocessing = list(
        na_method = "pca",
        log_transform = TRUE,
        standardization = TRUE
      )
    )
  ),

  exhaustive = list(
    name = "🔬 Recherche Exhaustive",
    description = "Analyse complète pour publication",
    time_estimate = "~30-60 minutes",
    settings = list(
      feature_selection = list(
        method = "clustEnet",
        n_clusters = 200,
        n_bootstrap = 1000
      ),
      model = list(
        type = "automl",
        tuning = "grid_search",
        cv_folds = 10,
        ensemble = TRUE
      ),
      preprocessing = list(
        na_method = "missForest",
        log_transform = TRUE,
        standardization = TRUE
      )
    )
  ),

  custom = list(
    name = "⚙️ Personnalisé",
    description = "Configuration manuelle complète",
    time_estimate = "Variable",
    settings = NULL  # User will configure
  )
)

##########################
# Preset Selection UI
##########################

create_preset_selector <- function() {

  preset_cards <- lapply(names(PRESET_CONFIGS), function(preset_id) {
    preset <- PRESET_CONFIGS[[preset_id]]

    div(
      class = "preset-card",
      onclick = sprintf("Shiny.setInputValue('selected_preset', '%s', {priority: 'event'})", preset_id),
      div(class = "preset-header", preset$name),
      div(class = "preset-description", preset$description),
      div(class = "preset-time", icon("clock"), preset$time_estimate),
      div(class = "preset-select-btn", "Sélectionner")
    )
  })

  tagList(
    tags$style(HTML("
      .preset-container {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 20px;
        margin: 20px 0;
      }
      .preset-card {
        background: white;
        border: 2px solid #e0e0e0;
        border-radius: 10px;
        padding: 20px;
        cursor: pointer;
        transition: all 0.3s ease;
        position: relative;
      }
      .preset-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        border-color: #3498db;
      }
      .preset-card.selected {
        border-color: #27ae60;
        background: #e8f8f5;
      }
      .preset-header {
        font-size: 18px;
        font-weight: bold;
        color: #2c3e50;
        margin-bottom: 10px;
      }
      .preset-description {
        color: #7f8c8d;
        font-size: 14px;
        margin-bottom: 15px;
        min-height: 40px;
      }
      .preset-time {
        color: #3498db;
        font-size: 13px;
        margin-bottom: 15px;
      }
      .preset-select-btn {
        background-color: #3498db;
        color: white;
        padding: 10px;
        border-radius: 5px;
        text-align: center;
        font-weight: bold;
        margin-top: 10px;
      }
      .preset-card:hover .preset-select-btn {
        background-color: #2980b9;
      }
      .preset-card.selected .preset-select-btn {
        background-color: #27ae60;
      }
    ")),
    div(class = "preset-container",
        do.call(tagList, preset_cards))
  )
}

##########################
# Quick Start Wizard
##########################

create_quick_start_wizard <- function() {

  tagList(
    h2("🚀 Démarrage Rapide"),

    p("Bienvenue ! Suivez ces étapes pour analyser vos données rapidement."),

    # Step 1: Choose preset
    wellPanel(
      h3("Étape 1 : Choisissez une Configuration"),
      create_preset_selector(),
      uiOutput("preset_details")
    ),

    # Step 2: Upload data
    conditionalPanel(
      condition = "input.selected_preset != null",
      wellPanel(
        h3("Étape 2 : Chargez vos Données"),
        fileInput("wizard_learning_file", "Fichier d'apprentissage",
                  accept = c(".csv", ".xlsx")),
        fileInput("wizard_validation_file", "Fichier de validation (optionnel)",
                  accept = c(".csv", ".xlsx")),
        uiOutput("data_preview_quick")
      )
    ),

    # Step 3: Confirm and run
    conditionalPanel(
      condition = "output.data_loaded",
      wellPanel(
        h3("Étape 3 : Lancer l'Analyse"),
        uiOutput("analysis_summary"),
        actionButton("run_wizard_analysis", "▶️ Démarrer l'Analyse",
                    class = "btn-primary btn-lg",
                    style = "width: 100%; font-size: 18px; padding: 15px;")
      )
    ),

    # Progress display
    uiOutput("wizard_progress")
  )
}

##########################
# Helper Functions
##########################

apply_preset_config <- function(preset_id) {
  if(preset_id == "custom") {
    return(NULL)  # User will configure manually
  }

  config <- PRESET_CONFIGS[[preset_id]]$settings
  return(config)
}

estimate_analysis_time <- function(n_samples, n_features, preset_id) {
  preset <- PRESET_CONFIGS[[preset_id]]

  # Base time estimation
  base_time <- switch(preset_id,
    "quick" = 5,
    "robust" = 15,
    "exhaustive" = 30,
    10
  )

  # Adjust for data size
  size_multiplier <- (n_samples / 100) * (n_features / 100)
  size_multiplier <- max(0.5, min(size_multiplier, 3))  # Cap between 0.5x and 3x

  estimated_minutes <- base_time * size_multiplier

  return(round(estimated_minutes))
}

##########################
# Validation Checklist
##########################

create_validation_checklist <- function(validation_results) {

  items <- list()

  # Class balance
  if(validation_results$imbalance$severity == "none") {
    items$balance <- list(status = "✅", text = "Classes équilibrées", color = "green")
  } else if(validation_results$imbalance$severity %in% c("moderate", "severe")) {
    items$balance <- list(status = "⚠️", text = sprintf("Déséquilibre détecté (ratio %.1f:1)",
                                                        validation_results$imbalance$ratio),
                         color = "orange")
  } else {
    items$balance <- list(status = "🔴", text = "Déséquilibre critique", color = "red")
  }

  # Missing data
  if(validation_results$missing$severity == "none") {
    items$missing <- list(status = "✅", text = "Peu de données manquantes", color = "green")
  } else {
    items$missing <- list(status = "⚠️",
                         text = sprintf("%.1f%% de données manquantes",
                                       validation_results$missing$total_percentage),
                         color = "orange")
  }

  # Sample size
  if(validation_results$sample_size$adequate) {
    items$size <- list(status = "✅", text = "Taille d'échantillon adéquate", color = "green")
  } else {
    items$size <- list(status = "⚠️", text = "Taille d'échantillon limite", color = "orange")
  }

  # Outliers
  if(validation_results$outliers$severity == "none") {
    items$outliers <- list(status = "✅", text = "Pas de valeurs aberrantes majeures", color = "green")
  } else {
    items$outliers <- list(status = "⚠️",
                          text = sprintf("%.1f%% de valeurs aberrantes",
                                        validation_results$outliers$overall_percentage),
                          color = "orange")
  }

  # Overall status
  overall <- validation_results$summary$overall_status
  overall_emoji <- if(overall == "good") "✅" else if(overall == "warning") "⚠️" else "🔴"

  # Create HTML
  checklist_html <- sprintf('
    <div class="validation-checklist">
      <h4>%s Statut de Validation : %s</h4>
      <ul>
        %s
      </ul>
      %s
    </div>
  ',
  overall_emoji,
  toupper(overall),
  paste(sapply(items, function(item) {
    sprintf('<li style="color: %s;">%s %s</li>', item$color, item$status, item$text)
  }), collapse = ""),
  if(length(validation_results$summary$warnings) > 0) {
    sprintf('<div class="warnings"><strong>Avertissements :</strong><ul>%s</ul></div>',
            paste(sapply(validation_results$summary$warnings,
                        function(w) sprintf("<li>%s</li>", w)), collapse = ""))
  } else ""
  )

  HTML(checklist_html)
}

##########################
# Mode Switch
##########################

create_mode_switch_ui <- function() {
  div(
    style = "text-align: right; margin-bottom: 20px;",
    radioButtons("ui_mode", "Mode d'interface :",
                c("🚀 Simple (Wizard)" = "wizard",
                  "⚙️ Avancé (Complet)" = "advanced"),
                inline = TRUE,
                selected = "wizard")
  )
}

message("UI Wizard system loaded")
