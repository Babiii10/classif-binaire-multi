################################################################################
# SERVER ENHANCEMENTS - Handlers for New Modules
################################################################################
# This file contains server-side handlers for the 4 integrated priority modules:
#   1. SMOTE (Class Imbalance Handling)
#   2. Model Export (PMML/RDS/JSON)
#   3. Reporting (HTML Reports)
#   4. Overfitting Detection
#
# To be sourced in server.R
################################################################################

################################################################################
# 1. SMOTE - CLASS IMBALANCE HANDLING
################################################################################

# Reactive value to store balanced data
balanced_data_reactive <- reactiveValues(
  train = NULL,
  test = NULL,
  applied = FALSE,
  method = NULL,
  summary = NULL
)

# Handler: Apply SMOTE balancing
observeEvent(input$apply_smote, {

  req(TRANSFORMDATA)

  withProgress(message = 'Applying class balancing...', value = 0, {

    tryCatch({

      # Prepare data
      if (exists("VALIDATA") && !is.null(VALIDATA) && nrow(VALIDATA) > 0) {
        # Split data into train/validation
        full_data <- rbind(
          cbind(TRANSFORMDATA, dataset = "train"),
          cbind(VALIDATA, dataset = "validation")
        )
        train_idx <- which(full_data$dataset == "train")
        test_idx <- which(full_data$dataset == "validation")
        full_data$dataset <- NULL
      } else {
        # Use only training data
        full_data <- TRANSFORMDATA
        train_idx <- 1:nrow(full_data)
        test_idx <- NULL
      }

      incProgress(0.3, detail = "Detecting imbalance...")

      # Apply balancing
      result <- balance_dataset(
        data = full_data,
        target_var = "group",
        method = input$smote_method,
        apply_to = input$smote_apply_to,
        train_indices = train_idx,
        test_indices = test_idx,
        auto_detect = TRUE
      )

      incProgress(0.6, detail = "Balancing data...")

      # Store results
      balanced_data_reactive$train <- result$train
      balanced_data_reactive$test <- result$test
      balanced_data_reactive$applied <- TRUE
      balanced_data_reactive$method <- result$method

      # Create summary
      train_summary <- table(result$train$group)
      summary_df <- data.frame(
        Class = names(train_summary),
        Count = as.integer(train_summary),
        stringsAsFactors = FALSE
      )
      balanced_data_reactive$summary <- summary_df

      incProgress(1.0, detail = "Complete!")

      # Update TRANSFORMDATA with balanced training data
      TRANSFORMDATA <<- result$train
      if (!is.null(result$test)) {
        VALIDATA <<- result$test
      }

      showNotification(
        "Class balancing applied successfully!",
        type = "message",
        duration = 5
      )

    }, error = function(e) {
      showNotification(
        paste("Balancing failed:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
})

# Output: SMOTE status
output$smote_status <- renderUI({
  if (balanced_data_reactive$applied) {
    tags$div(
      style = "color: green; font-weight: bold;",
      icon("check-circle"),
      paste("Applied:", balanced_data_reactive$method)
    )
  } else {
    tags$div(
      style = "color: gray;",
      "Not yet applied"
    )
  }
})

# Output: Check if SMOTE was applied
output$smote_applied <- reactive({
  balanced_data_reactive$applied
})
outputOptions(output, "smote_applied", suspendWhenHidden = FALSE)

# Output: SMOTE distribution plot
output$plot_smote_distribution <- renderPlot({
  req(balanced_data_reactive$applied)
  req(balanced_data_reactive$train)

  # Before balancing (original SELECTDATA or TRANSFORMDATA before balancing)
  # For now, show current distribution
  plot_class_distribution(
    original_data = SELECTDATA,
    balanced_data = balanced_data_reactive$train,
    target_var = "group"
  )
})

# Output: SMOTE summary table
output$table_smote_summary <- renderTable({
  req(balanced_data_reactive$summary)
  balanced_data_reactive$summary
})

################################################################################
# 2. MODEL EXPORT
################################################################################

# Handler: Export model
observeEvent(input$export_model_btn, {

  req(MODEL)
  req(input$export_formats)

  withProgress(message = 'Exporting model...', value = 0, {

    tryCatch({

      # Get model type
      model_type <- input$model
      if (is.null(model_type) || model_type == "") {
        model_type <- "randomforest"  # default
      }

      incProgress(0.3, detail = paste("Exporting to", paste(input$export_formats, collapse = ", ")))

      # Export
      export_result <- export_model(
        model = MODEL,
        model_type = model_type,
        data = TRANSFORMDATA,
        output_dir = "model_exports",
        formats = input$export_formats,
        model_name = paste0(model_type, "_", format(Sys.Date(), "%Y%m%d"))
      )

      incProgress(1.0, detail = "Export complete!")

      # Show success message
      exported_files <- paste(
        paste0(model_type, "_", format(Sys.Date(), "%Y%m%d"), ".", input$export_formats),
        collapse = ", "
      )

      showNotification(
        paste("Model exported successfully! Files:", exported_files),
        type = "message",
        duration = 10
      )

      # Update status
      output$export_status <- renderUI({
        tags$div(
          style = "color: green; font-weight: bold; margin-top: 10px;",
          icon("check-circle"),
          " Export successful!",
          tags$br(),
          tags$small(paste("Location: model_exports/"))
        )
      })

    }, error = function(e) {
      output$export_status <- renderUI({
        tags$div(
          style = "color: red; font-weight: bold; margin-top: 10px;",
          icon("exclamation-triangle"),
          paste(" Export failed:", e$message)
        )
      })

      showNotification(
        paste("Model export failed:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
})

################################################################################
# 3. REPORTING - HTML REPORT GENERATION
################################################################################

# Reactive value for report
report_data <- reactiveValues(
  generated = FALSE,
  filepath = NULL
)

# Handler: Generate report
observeEvent(input$generate_report, {

  withProgress(message = 'Generating analysis report...', value = 0, {

    tryCatch({

      incProgress(0.2, detail = "Preparing data...")

      # Prepare analysis results
      analysis_results <- list(
        data_summary = list(
          n_samples = nrow(DATA),
          n_features = ncol(DATA) - 1,
          n_classes = length(levels(DATA$group)),
          class_levels = levels(DATA$group),
          class_distribution = table(DATA$group)
        ),
        preprocessing = list(
          missing_imputation = if(exists("input") && !is.null(input$rempNA)) input$rempNA else "none",
          log_transform = if(exists("input") && !is.null(input$log)) input$log else FALSE,
          standardization = if(exists("input") && !is.null(input$standardization)) input$standardization else FALSE
        ),
        feature_selection = list(
          method = if(exists("SELECTMETHOD")) SELECTMETHOD else "none",
          n_features_selected = if(exists("SELECTDATA")) ncol(SELECTDATA) - 1 else 0
        ),
        model_results = if(exists("MODEL") && !is.null(MODEL)) {
          list(
            model_type = input$model,
            train_auc = if(exists("STATISTICS") && !is.null(STATISTICS$auclearn)) STATISTICS$auclearn else NA,
            train_accuracy = if(exists("STATISTICS") && !is.null(STATISTICS$accuracy)) STATISTICS$accuracy else NA,
            validation_auc = if(exists("STATISTICS") && !is.null(STATISTICS$aucval)) STATISTICS$aucval else NA,
            validation_accuracy = if(exists("STATISTICS") && !is.null(STATISTICS$accuracyval)) STATISTICS$accuracyval else NA
          )
        } else {
          NULL
        }
      )

      incProgress(0.5, detail = "Generating HTML...")

      # Generate report
      output_file <- file.path(tempdir(), paste0("analysis_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html"))

      generate_analysis_report(
        analysis_results = analysis_results,
        output_file = output_file,
        format = "html",
        include_plots = TRUE
      )

      incProgress(1.0, detail = "Report ready!")

      # Store filepath
      report_data$generated <- TRUE
      report_data$filepath <- output_file

      showNotification(
        "Analysis report generated successfully!",
        type = "message",
        duration = 5
      )

    }, error = function(e) {
      showNotification(
        paste("Report generation failed:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
})

# Output: Report ready status
output$report_ready <- reactive({
  report_data$generated
})
outputOptions(output, "report_ready", suspendWhenHidden = FALSE)

# Handler: Download report
output$download_report <- downloadHandler(
  filename = function() {
    paste0("analysis_report_", format(Sys.Date(), "%Y%m%d"), ".html")
  },
  content = function(file) {
    file.copy(report_data$filepath, file)
  }
)

################################################################################
# 4. OVERFITTING DETECTION
################################################################################

# Reactive value for overfitting analysis
overfitting_analysis <- reactiveValues(
  detected = FALSE,
  status = NULL,
  auc_diff = NULL,
  acc_diff = NULL,
  suggestions = NULL
)

# Automatic overfitting detection after model training
observe({

  # Trigger when model results are available
  req(STATISTICS)
  req(STATISTICS$auclearn)
  req(STATISTICS$aucval)

  tryCatch({

    # Prepare metrics
    train_metrics <- list(
      auc = STATISTICS$auclearn,
      accuracy = if(!is.null(STATISTICS$accuracy)) STATISTICS$accuracy else NA
    )

    val_metrics <- list(
      auc = STATISTICS$aucval,
      accuracy = if(!is.null(STATISTICS$accuracyval)) STATISTICS$accuracyval else NA
    )

    # Detect overfitting
    overfitting_result <- detect_overfitting(
      train_metrics = train_metrics,
      val_metrics = val_metrics,
      threshold_severe = 0.15,
      threshold_moderate = 0.08,
      detailed = TRUE
    )

    # Store results
    overfitting_analysis$detected <- TRUE
    overfitting_analysis$status <- overfitting_result$status
    overfitting_analysis$auc_diff <- overfitting_result$auc_diff
    overfitting_analysis$acc_diff <- overfitting_result$acc_diff

    # Get suggestions if overfitting detected
    if (overfitting_result$status %in% c("moderate_overfitting", "severe_overfitting")) {
      model_type <- if(!is.null(input$model)) input$model else "randomforest"
      overfitting_analysis$suggestions <- suggest_model_adjustments(
        model_type = model_type,
        overfitting_analysis = overfitting_result
      )
    }

  }, error = function(e) {
    # Silent fail - overfitting detection is optional
  })
})

# Output: Overfitting alert
output$overfitting_alert <- renderUI({

  if (!overfitting_analysis$detected) {
    return(tags$div(
      style = "color: gray; font-size: 0.9em;",
      icon("info-circle"),
      " Train model to see overfitting analysis"
    ))
  }

  status <- overfitting_analysis$status

  if (status == "good_generalization") {
    tags$div(
      class = "alert alert-success",
      style = "padding: 10px; margin: 5px 0;",
      icon("check-circle"),
      strong(" Excellent!"),
      tags$br(),
      "Good generalization"
    )
  } else if (status == "acceptable") {
    tags$div(
      class = "alert alert-info",
      style = "padding: 10px; margin: 5px 0;",
      icon("info-circle"),
      strong(" Acceptable"),
      tags$br(),
      "Minor overfitting"
    )
  } else if (status == "moderate_overfitting") {
    tags$div(
      class = "alert alert-warning",
      style = "padding: 10px; margin: 5px 0;",
      icon("exclamation-triangle"),
      strong(" Moderate Overfitting"),
      tags$br(),
      sprintf("AUC diff: %.3f", overfitting_analysis$auc_diff)
    )
  } else if (status == "severe_overfitting") {
    tags$div(
      class = "alert alert-danger",
      style = "padding: 10px; margin: 5px 0;",
      icon("exclamation-circle"),
      strong(" Severe Overfitting!"),
      tags$br(),
      sprintf("AUC diff: %.3f", overfitting_analysis$auc_diff)
    )
  }
})

# Output: Overfitting detected flag
output$overfitting_detected <- reactive({
  overfitting_analysis$detected &&
    overfitting_analysis$status %in% c("moderate_overfitting", "severe_overfitting")
})
outputOptions(output, "overfitting_detected", suspendWhenHidden = FALSE)

# Output: Overfitting plot
output$plot_overfitting <- renderPlot({
  req(overfitting_analysis$detected)
  req(STATISTICS)

  # Create simple bar plot
  metrics_df <- data.frame(
    Metric = c("AUC Train", "AUC Val"),
    Value = c(STATISTICS$auclearn, STATISTICS$aucval)
  )

  ggplot(metrics_df, aes(x = Metric, y = Value, fill = Metric)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "red") +
    scale_fill_manual(values = c("AUC Train" = "#3498db", "AUC Val" = "#e74c3c")) +
    ylim(0, 1) +
    labs(title = "Train vs Validation Performance",
         y = "AUC") +
    theme_minimal() +
    theme(legend.position = "none")
})

# Output: Overfitting suggestions
output$overfitting_suggestions_text <- renderUI({
  req(overfitting_analysis$suggestions)

  suggestions_list <- overfitting_analysis$suggestions

  tags$div(
    tags$ul(
      lapply(suggestions_list, function(s) {
        tags$li(s)
      })
    )
  )
})

################################################################################
# END OF SERVER ENHANCEMENTS
################################################################################

message("✓ Server enhancements loaded (SMOTE, Export, Reporting, Overfitting)")
