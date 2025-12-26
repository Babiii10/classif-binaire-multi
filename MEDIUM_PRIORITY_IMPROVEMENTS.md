# MEDIUM PRIORITY IMPROVEMENTS - Documentation

**Version:** 2.1.0
**Date:** 2025-12-26
**Status:** ✅ Implemented

## Overview

This document describes the 4 MEDIUM PRIORITY improvements implemented to enhance the classification application's interpretability, deployment capabilities, data quality handling, and user experience.

---

## Table of Contents

1. [Module 1: SHAP/LIME Interpretability](#module-1-shaplime-interpretability)
2. [Module 2: Standardized Model Export (PMML)](#module-2-standardized-model-export-pmml)
3. [Module 3: SMOTE & Imbalanced Class Handling](#module-3-smote--imbalanced-class-handling)
4. [Module 4: Preset Configurations](#module-4-preset-configurations)
5. [Installation](#installation)
6. [Integration](#integration)
7. [Complete Usage Examples](#complete-usage-examples)

---

## Module 1: SHAP/LIME Interpretability

**File:** `interpretability.R` (700+ lines)

### Purpose

Make machine learning models interpretable and explainable using industry-standard methods:
- **SHAP** (SHapley Additive exPlanations): Global and local feature importance
- **LIME** (Local Interpretable Model-agnostic Explanations): Individual prediction explanations
- **Permutation Importance**: Model-agnostic feature ranking

### Key Features

✅ **SHAP Analysis**
- Calculate SHAP values for any model type
- Feature importance ranking (mean absolute SHAP)
- Summary plots (beeswarm style)
- Supports all major models: RandomForest, XGBoost, SVM, ElasticNet, KNN

✅ **LIME Explanations**
- Explain individual predictions
- Local feature contributions
- Model-agnostic approach

✅ **Permutation Importance**
- Robust feature importance estimation
- Works with any model
- Multiple iterations for stability

✅ **Automated Reporting**
- HTML interpretation reports
- Feature importance tables
- Visual explanations

### Dependencies (Optional)

```r
install.packages(c("DALEX", "iml", "fastshap", "ggplot2"))
```

**Note:** If packages are missing, the module provides graceful fallbacks.

### Usage Examples

#### Basic SHAP Analysis

```r
# Train a model
model <- randomForest(group ~ ., data = training_data)

# Calculate SHAP values
shap_results <- calculate_shap(
  model = model,
  data = training_data,
  model_type = "randomforest",
  nsim = 100  # Monte Carlo simulations
)

# View feature importance
print(shap_results$feature_importance)
#>          feature importance
#> 1  gene_marker_1      0.245
#> 2  gene_marker_5      0.189
#> 3  clinical_var3      0.156
```

#### LIME for Individual Predictions

```r
# Explain why model predicted class X for patient 42
lime_result <- calculate_lime(
  model = model,
  data = training_data,
  newdata = test_data[42, ],  # Single patient
  model_type = "randomforest",
  n_features = 5  # Top 5 contributing features
)

# View explanation
print(lime_result$lime_explanation)
```

#### Comprehensive Model Explanation

```r
# Generate full interpretation with SHAP + Permutation
explanation <- explain_model(
  model = model,
  data = training_data,
  newdata = test_data[1:10, ],  # Explain 10 predictions
  model_type = "randomforest",
  methods = c("shap", "permutation"),
  output_file = "model_interpretation.html"
)

# Results:
# - SHAP feature importance
# - Permutation importance
# - Individual prediction explanations
# - HTML report saved
```

#### Visualizations

```r
# Create SHAP plots
plots <- create_shap_plots(shap_results)

# Feature importance plot
print(plots$feature_importance)

# Summary plot (distribution of SHAP values)
print(plots$summary)
```

### Output Structure

```r
explanation_result <- list(
  shap = list(
    shap_values = matrix,          # SHAP values for each sample/feature
    feature_importance = data.frame,  # Ranked features
    plots = list(...)                # ggplot2 visualizations
  ),
  permutation = data.frame(
    feature = c("gene1", "gene2", ...),
    importance = c(0.15, 0.12, ...)
  ),
  lime = list(...)  # Individual explanations
)
```

### Use Cases

1. **Research Publications**: Identify which biomarkers drive predictions
2. **Clinical Applications**: Explain individual patient risk predictions
3. **Model Debugging**: Detect if model relies on spurious features
4. **Regulatory Compliance**: Provide explainability for medical AI

---

## Module 2: Standardized Model Export (PMML)

**File:** `model_export.R` (550+ lines)

### Purpose

Export trained models to standardized formats for cross-platform deployment and production use.

### Supported Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **PMML** | Predictive Model Markup Language | Cross-platform deployment (Java, Python, C++) |
| **RDS** | R native format with metadata | R environments, complete model preservation |
| **JSON** | Model configuration and parameters | APIs, documentation, version control |

### Key Features

✅ **PMML Export**
- Industry-standard XML format
- Supports: RandomForest, SVM, ElasticNet, XGBoost
- Compatible with Java (JPMML), Python (PyPMML), KNIME, SAS

✅ **Enhanced RDS Export**
- Complete model object
- Rich metadata (features, classes, R version, package versions)
- Training data (optional)
- Load/validation functions

✅ **JSON Configuration**
- Model parameters
- Feature names and types
- Hyperparameters
- Human-readable format

✅ **Deployment Guides**
- Automatic generation of deployment documentation
- Usage examples in R, Python, Java
- Deployment checklists

### Dependencies (Optional)

```r
install.packages(c("r2pmml", "pmml", "jsonlite"))
```

### Usage Examples

#### Export Single Model to PMML

```r
# Train model
rf_model <- randomForest(group ~ ., data = training_data, ntree = 500)

# Export to PMML
export_to_pmml(
  model = rf_model,
  model_type = "randomforest",
  data = training_data,
  output_file = "production_model.pmml",
  model_name = "PatientClassifier_v1.0"
)
#> ✓ Model exported to PMML: production_model.pmml
```

#### Export with Metadata (RDS)

```r
# Export with comprehensive metadata
export_to_rds_with_metadata(
  model = rf_model,
  model_type = "randomforest",
  data = training_data,
  output_file = "model_v1.rds",
  include_data = FALSE  # TRUE to include training data
)

# Load model later
model_pkg <- load_model_from_rds("model_v1.rds")
#> === Model Metadata ===
#> Model Type: randomforest
#> Created: 2025-12-26 10:30:00
#> Features: 150
#> Classes: 2
#> Training Samples: 500
#> ====================

model <- model_pkg$model
```

#### Export to Multiple Formats

```r
# Export to PMML, RDS, and JSON simultaneously
export_results <- export_model(
  model = xgb_model,
  model_type = "xgboost",
  data = training_data,
  output_dir = "exports/production",
  formats = c("pmml", "rds", "json"),
  model_name = "XGBoost_Classifier_v2"
)

#> === Exporting Model ===
#> Model: XGBoost_Classifier_v2
#> Formats: pmml, rds, json
#> Output directory: exports/production
#>
#> ✓ Model exported to PMML: exports/production/XGBoost_Classifier_v2.pmml
#> ✓ Model exported to RDS: exports/production/XGBoost_Classifier_v2.rds
#> ✓ Model configuration exported to JSON: exports/production/XGBoost_Classifier_v2.json
#>
#> === Export Summary ===
#> PMML: ✓ Success
#> RDS:  ✓ Success
#> JSON: ✓ Success
#> ===================
```

#### Generate Deployment Guide

```r
# Create deployment documentation
generate_deployment_guide(
  model_type = "xgboost",
  output_dir = "exports/production",
  model_name = "XGBoost_Classifier_v2"
)
#> Deployment guide saved to: exports/production/XGBoost_Classifier_v2_deployment_guide.md
```

### PMML Usage in Other Languages

#### Python (PyPMML)

```python
from pypmml import Model

# Load PMML model
model = Model.load('production_model.pmml')

# Make predictions
predictions = model.predict(new_data)
```

#### Java (JPMML)

```java
import org.jpmml.evaluator.*;

// Load PMML
Evaluator evaluator = new LoadingModelEvaluatorBuilder()
    .load(new File("production_model.pmml"))
    .build();

// Predict
Map<FieldName, ?> predictions = evaluator.evaluate(arguments);
```

### JSON Export Structure

```json
{
  "metadata": {
    "model_type": "randomforest",
    "created_date": "2025-12-26 10:30:00",
    "n_features": 150,
    "n_classes": 2,
    "class_levels": ["control", "disease"]
  },
  "parameters": {
    "ntree": 500,
    "mtry": 12,
    "nodesize": 5
  },
  "feature_names": ["gene1", "gene2", ...]
}
```

### Use Cases

1. **Production Deployment**: Export to PMML for Java/Python microservices
2. **Model Versioning**: Track model versions with JSON configurations
3. **Cross-Team Collaboration**: Share models with non-R teams
4. **Regulatory Compliance**: Archive models with complete metadata

---

## Module 3: SMOTE & Imbalanced Class Handling

**File:** `smote.R` (650+ lines)

### Purpose

Handle imbalanced classification datasets where one class has significantly fewer samples than others.

### Methods Available

| Method | Description | When to Use |
|--------|-------------|-------------|
| **SMOTE** | Synthetic Minority Over-sampling | Moderate to severe imbalance |
| **ADASYN** | Adaptive Synthetic Sampling | Severe imbalance with local density issues |
| **Random Oversampling** | Duplicate minority samples | Mild imbalance |
| **Random Undersampling** | Remove majority samples | Large datasets with imbalance |
| **Hybrid** | SMOTE + Undersampling | Severe imbalance, balanced approach |

### Key Features

✅ **Automatic Imbalance Detection**
- Calculate imbalance ratio (majority:minority)
- Classify severity: balanced, moderate, high, severe
- Recommend appropriate method

✅ **User Choice: Train and/or Validation**
- Apply balancing to training set only (recommended)
- Apply to validation set (for specific use cases)
- Apply to both sets

✅ **Smart Recommendations**
- Auto-detect imbalance severity
- Suggest optimal balancing method
- Provide before/after statistics

✅ **Visualization**
- Class distribution plots
- Before/after comparison

### Dependencies (Optional)

```r
install.packages(c("smotefamily", "ROSE", "DMwR"))
```

### Usage Examples

#### Detect Imbalance

```r
# Check if data is imbalanced
imbalance_info <- detect_class_imbalance(
  data = training_data,
  target_var = "group",
  threshold_ratio = 2.0
)

print(imbalance_info)
#> $is_imbalanced
#> [1] TRUE
#>
#> $imbalance_ratio
#> [1] 5.3
#>
#> $severity
#> [1] "high"
#>
#> $class_counts
#> disease control
#>     150     795
#>
#> $recommendation
#> [1] "Recommended: SMOTE or hybrid sampling (ratio: 5.3:1)"
```

#### Apply SMOTE to Training Set

```r
# Balance training data with SMOTE
balanced_result <- balance_dataset(
  data = full_data,
  target_var = "group",
  method = "smote",
  apply_to = "train",  # Only balance training set
  train_indices = train_idx,
  test_indices = test_idx
)

#> === Class Imbalance Handling ===
#> Imbalance detected:
#>   Severity: high
#>   Ratio: 5.3:1
#>   Majority class: control (795 samples)
#>   Minority class: disease (150 samples)
#>   Recommendation: Recommended: SMOTE or hybrid sampling
#>
#> Applying method: smote
#> Target sets: train
#> Applying SMOTE...
#>   Original distribution: disease = 105, control = 556
#>   New distribution:      disease = 315, control = 556
#> === Balancing Complete ===

# Use balanced data for training
model <- randomForest(group ~ ., data = balanced_result$train)

# Evaluate on original (unbalanced) validation set
predictions <- predict(model, balanced_result$test)
```

#### Compare Multiple Methods

```r
# Try different balancing methods
methods <- c("smote", "adasyn", "oversample", "hybrid")

results <- lapply(methods, function(m) {
  balanced <- balance_dataset(
    data = full_data,
    method = m,
    apply_to = "train",
    train_indices = train_idx,
    test_indices = test_idx
  )

  # Train and evaluate
  model <- randomForest(group ~ ., data = balanced$train)
  pred <- predict(model, balanced$test)
  auc <- calculate_auc(balanced$test$group, pred)

  return(list(method = m, auc = auc))
})
```

#### Auto-Select Best Method

```r
# Let the system choose the best method automatically
balanced_result <- balance_dataset(
  data = full_data,
  method = "auto",  # Auto-select based on severity
  apply_to = "train",
  auto_detect = TRUE
)
#> Auto-selected method: hybrid  # For severe imbalance
```

#### Specific Methods

```r
# SMOTE with custom parameters
smote_data <- apply_smote(
  data = training_data,
  target_var = "group",
  perc_over = 200,    # 200% oversampling of minority
  perc_under = 200,   # 200% undersampling of majority
  k = 5               # 5 nearest neighbors
)

# ADASYN (adaptive)
adasyn_data <- apply_adasyn(
  data = training_data,
  target_var = "group",
  k = 5
)

# Random oversampling
over_data <- apply_random_oversampling(
  data = training_data,
  ratio = 1.0  # Perfect balance (1:1)
)

# Random undersampling
under_data <- apply_random_undersampling(
  data = training_data,
  ratio = 1.0
)

# Hybrid (SMOTE + undersampling)
hybrid_data <- apply_hybrid_sampling(
  data = training_data,
  smote_ratio = 1.5,
  undersample_ratio = 1.2
)
```

#### Visualization

```r
# Plot class distribution before/after
plot <- plot_class_distribution(
  original_data = training_data,
  balanced_data = balanced_result$train,
  target_var = "group"
)

print(plot)
```

### Important Considerations

**✅ RECOMMENDED:**
- Apply balancing to **training set only**
- Evaluate on **original (unbalanced) validation set**
- This prevents data leakage and gives realistic performance metrics

**⚠️ CAUTION:**
- Applying to validation set can inflate metrics
- Only use for specific scenarios (e.g., cost-sensitive learning)

### Imbalance Severity Classification

| Ratio | Severity | Recommendation |
|-------|----------|----------------|
| < 2:1 | Balanced | No action needed |
| 2-5:1 | Moderate | Random oversampling or class weights |
| 5-10:1 | High | SMOTE or hybrid sampling |
| > 10:1 | Severe | Hybrid or ADASYN |

### Use Cases

1. **Medical Diagnosis**: Rare disease detection (1% positive cases)
2. **Fraud Detection**: Fraudulent transactions are rare
3. **Quality Control**: Defects are uncommon
4. **Churn Prediction**: Most customers don't churn

---

## Module 4: Preset Configurations

**File:** `presets.R` (600+ lines)

### Purpose

Provide predefined analysis configurations for common use cases, eliminating the need for manual parameter tuning.

### Available Presets

| Preset | Time | Use Case | Models | Key Features |
|--------|------|----------|--------|--------------|
| **Quick** | ~5 min | Exploratory analysis, POC | RandomForest | Minimal validation, fast |
| **Standard** | ~15-20 min | General purpose | RF, XGBoost, ElasticNet | Balanced accuracy/speed |
| **Robust** | ~30-40 min | Critical applications | RF, XGBoost, SVM, ElasticNet | 10-fold CV, SMOTE, stacking |
| **Publication** | ~60-90 min | Research papers | All 6 models | Nested CV, comprehensive |
| **Exploratory** | ~45-60 min | Finding best approach | Multiple configs | Grid search, all methods |
| **Production** | ~20-30 min | Deployment | RF, XGBoost | Optimized for inference |

### Key Features

✅ **Complete Workflow Configuration**
- Preprocessing settings
- Feature selection method
- Model selection and parameters
- Validation strategy
- Performance optimization
- Advanced features (ensemble, AutoML, etc.)

✅ **Smart Recommendations**
- Auto-recommend preset based on:
  - Dataset size
  - Number of features
  - Time constraints
  - Imbalance ratio

✅ **Easy Customization**
- Override any parameter
- Save custom presets
- Import/export as JSON

✅ **Comparison Tools**
- Compare multiple presets
- Display preset details
- Time estimates

### Usage Examples

#### Apply a Preset

```r
# Load and apply Standard preset
preset <- apply_preset("standard")

#> Applying preset: Standard Analysis
#> Description: Balanced analysis with good accuracy and reasonable speed
#> Estimated time: ~15-20 minutes

# Preset is now active and configurations are set
```

#### View Preset Configuration

```r
# Get preset details
robust_preset <- get_preset("robust")

print(robust_preset$preprocessing)
#> $missing_values
#> [1] "mice"
#>
#> $missing_threshold
#> [1] 0.15
#>
#> $log_transform
#> [1] TRUE
#>
#> $standardization
#> [1] TRUE

print(robust_preset$models)
#> [1] "randomforest" "xgboost" "svm" "elasticnet"

print(robust_preset$validation$cv_folds)
#> [1] 10
```

#### Compare Presets

```r
# Compare multiple presets
comparison <- compare_presets(c("quick", "standard", "robust", "publication"))

print(comparison)
#>            Preset          Time                          Models Validation Features Ensemble
#> 1   Quick Analysis      ~5 min                    randomforest    holdout      all    FALSE
#> 2 Standard Analysis ~15-20 min randomforest, xgboost, elasticnet         cv       50     TRUE
#> 3  Robust Analysis ~30-40 min randomforest, xgboost, svm, ela...         cv      100     TRUE
#> 4 Publication Ready ~60-90 min randomforest, xgboost, svm, ela...  nested_cv      150     TRUE
```

#### Display All Presets

```r
# Show comparison table
display_preset_comparison()

#> === PRESET COMPARISON ===
#> [Table with all 6 presets]
#> ========================
```

#### Get Recommendation

```r
# Auto-recommend based on dataset
recommended <- recommend_preset(
  n_samples = 500,
  n_features = 200,
  n_classes = 3,
  imbalance_ratio = 4.5,
  time_constraint = 30  # 30 minutes available
)

#> === Preset Recommendation ===
#> Dataset: 500 samples, 200 features, 3 classes
#> Imbalance ratio: 4.5:1
#> Recommendation: 'robust' (severe imbalance)
```

#### Override Preset Parameters

```r
# Start with Standard preset but customize
preset <- apply_preset(
  "standard",
  override = list(
    models = c("randomforest", "xgboost"),  # Use only these 2
    validation = list(
      cv_folds = 10  # Increase from 5 to 10
    ),
    advanced = list(
      enable_automl = TRUE  # Add AutoML
    )
  )
)
```

#### Create and Save Custom Preset

```r
# Define custom preset
my_preset <- list(
  name = "My Custom Analysis",
  description = "Optimized for genomic data",
  time_estimate = "~25 minutes",

  preprocessing = list(
    missing_values = "knn",
    log_transform = TRUE,
    standardization = TRUE
  ),

  models = c("randomforest", "elasticnet"),

  validation = list(
    method = "cv",
    cv_folds = 5
  )
)

# Save for future use
save_custom_preset(my_preset, name = "genomics_analysis")
#> Custom preset saved to: presets/genomics_analysis.rds

# Load later
loaded_preset <- load_custom_preset("genomics_analysis")
```

#### Export/Import Presets as JSON

```r
# Export preset to JSON (for version control, sharing)
export_preset_to_json("standard", "configs/standard_preset.json")

# Import custom preset from JSON
imported_preset <- import_preset_from_json("configs/custom_config.json")
apply_preset(imported_preset)
```

### Preset Configurations in Detail

#### QUICK Preset
```r
- Time: ~5 minutes
- Preprocessing: Minimal (simple imputation, no transforms)
- Feature Selection: None (all features)
- Models: RandomForest (100 trees)
- Validation: Holdout (70/30 split)
- Parallel: Disabled
- Imbalance: Not handled
- Ensemble: Disabled
- Report: Not generated
```

#### STANDARD Preset (Recommended)
```r
- Time: ~15-20 minutes
- Preprocessing: KNN imputation, log transform, standardization
- Feature Selection: p-value < 0.05, top 50 features
- Models: RandomForest, XGBoost, ElasticNet
- Validation: 5-fold CV + bootstrap (50 iter)
- Parallel: Enabled
- Imbalance: Auto-detect and balance training set
- Ensemble: Averaging
- Report: HTML generated
```

#### ROBUST Preset
```r
- Time: ~30-40 minutes
- Preprocessing: MICE imputation, outlier removal
- Feature Selection: p-value < 0.01, top 100 features
- Models: RandomForest (1000 trees), XGBoost, SVM, ElasticNet
- Validation: 10-fold stratified CV + 100 bootstrap
- Parallel: Enabled
- Imbalance: SMOTE on training set
- Ensemble: Stacking
- AutoML: Enabled
- Overfitting Detection: Enabled
- Report: Comprehensive HTML
```

#### PUBLICATION Preset
```r
- Time: ~60-90 minutes
- Preprocessing: MICE, detailed outlier analysis
- Feature Selection: Combined methods, top 150
- Models: All 6 models (RF, XGBoost, SVM, ElasticNet, KNN, NaiveBayes)
- Validation: Nested 10-fold CV (5 repetitions) + 200 bootstrap
- Parallel: Enabled
- Imbalance: Hybrid sampling
- Ensemble: Stacking
- AutoML: Enabled
- Interpretability: SHAP + Permutation
- Overfitting Detection: Enabled
- Model Export: PMML, RDS, JSON
- Report: Publication-quality HTML
```

#### EXPLORATORY Preset
```r
- Time: ~45-60 minutes
- Preprocessing: Try multiple imputation methods
- Feature Selection: Try all methods with multiple feature counts
- Models: 5 models with grid search
- Validation: 5-fold CV
- Parallel: Enabled
- Imbalance: Compare multiple balancing methods
- Ensemble: Try all ensemble methods
- AutoML: Enabled
- Report: Generated
```

#### PRODUCTION Preset
```r
- Time: ~20-30 minutes
- Preprocessing: Fast (simple imputation)
- Feature Selection: Top 30 features (fewer = faster inference)
- Models: RandomForest (200 trees), XGBoost (optimized)
- Validation: 5-fold CV, 80/20 train/test split
- Parallel: Enabled
- Imbalance: Auto-handled
- Ensemble: Disabled (single model for speed)
- AutoML: Enabled (optimize for balanced accuracy)
- Model Export: PMML + RDS for deployment
- Inference Optimization: Enabled
- Report: Generated
```

### Use Cases

1. **Quick Exploration**: Use "quick" preset to get initial results in 5 minutes
2. **Standard Analysis**: Use "standard" for most classification tasks
3. **Critical Applications**: Use "robust" for medical/financial applications
4. **Research Papers**: Use "publication" for comprehensive analysis
5. **Method Selection**: Use "exploratory" to find best approach
6. **Deployment**: Use "production" for optimized inference

---

## Installation

### Core Application
The application is already installed with all priority improvements.

### Medium Priority Improvements - Optional Dependencies

```r
# Install all optional packages for full functionality
install.packages(c(
  # Interpretability
  "DALEX", "iml", "fastshap",

  # Model Export
  "r2pmml", "pmml", "jsonlite",

  # Imbalance Handling
  "smotefamily", "ROSE", "DMwR",

  # Visualization
  "ggplot2", "reshape2"
))
```

### Minimal Installation (No Optional Packages)

All modules work with graceful degradation if optional packages are missing:

- **interpretability.R**: Provides basic permutation importance without SHAP/LIME
- **model_export.R**: Exports to RDS format without PMML
- **smote.R**: Falls back to random sampling methods
- **presets.R**: Works fully (no dependencies)

---

## Integration

All 4 modules are automatically loaded when the application starts via `global.R`:

```r
# In global.R (lines 148-183)

# Load interpretability module (SHAP/LIME)
tryCatch({
  source("interpretability.R", local = TRUE)
  message("✓ Interpretability module loaded (SHAP/LIME)")
}, error = function(e) {
  warning(paste("Could not load interpretability.R:", e$message))
})

# Load model export module (PMML)
tryCatch({
  source("model_export.R", local = TRUE)
  message("✓ Model export module loaded (PMML/RDS/JSON)")
}, error = function(e) {
  warning(paste("Could not load model_export.R:", e$message))
})

# Load SMOTE & imbalance handling
tryCatch({
  source("smote.R", local = TRUE)
  message("✓ SMOTE & imbalance handling loaded")
}, error = function(e) {
  warning(paste("Could not load smote.R:", e$message))
})

# Load preset configurations
tryCatch({
  source("presets.R", local = TRUE)
  message("✓ Preset configurations loaded")
}, error = function(e) {
  warning(paste("Could not load presets.R:", e$message))
})
```

### Integration with UI (Future Work)

To integrate these features into the Shiny UI:

1. **Interpretability Tab**: Add SHAP/LIME explanations after model training
2. **Export Button**: Add model export options with format selection
3. **Imbalance Settings**: Add SMOTE configuration in preprocessing panel
4. **Preset Selector**: Add dropdown to select analysis preset

---

## Complete Usage Examples

### Example 1: Complete Robust Analysis Workflow

```r
# Step 1: Load and apply ROBUST preset
preset <- apply_preset("robust")

# Step 2: Load data
data <- read.csv("patient_data.csv")

# Step 3: Detect and handle imbalance
balanced_result <- balance_dataset(
  data = data,
  method = "smote",
  apply_to = "train",
  train_indices = train_idx,
  test_indices = test_idx,
  auto_detect = TRUE
)

# Step 4: Train models (using preset configuration)
models <- list()
for (model_type in preset$models) {
  models[[model_type]] <- train_model(
    data = balanced_result$train,
    type = model_type,
    params = preset$model_params[[model_type]]
  )
}

# Step 5: Create ensemble
ensemble <- create_ensemble(
  models = models,
  model_types = names(models),
  combination_method = preset$advanced$ensemble_method,  # "stacking"
  training_data = balanced_result$train
)

# Step 6: Evaluate
predictions <- predict_ensemble(ensemble, balanced_result$test)
auc <- calculate_auc(balanced_result$test$group, predictions)

# Step 7: Explain best model
shap_results <- explain_model(
  model = models$randomforest,
  data = balanced_result$train,
  newdata = balanced_result$test[1:20, ],
  model_type = "randomforest",
  methods = c("shap", "permutation"),
  output_file = "interpretation_report.html"
)

# Step 8: Export for production
export_model(
  model = ensemble,
  model_type = "ensemble",
  data = balanced_result$train,
  output_dir = "production/models",
  formats = c("rds", "pmml", "json"),
  model_name = "PatientClassifier_v1.0"
)
```

### Example 2: Quick Exploratory Analysis

```r
# Use QUICK preset for fast iteration
preset <- apply_preset("quick")

data <- read.csv("new_dataset.csv")

# Quick model
model <- randomForest(group ~ ., data = data, ntree = 100)

# Quick evaluation
pred <- predict(model, data, type = "prob")
auc <- calculate_auc(data$group, pred[, 2])

print(paste("Quick AUC:", round(auc, 3)))
#> "Quick AUC: 0.867"

# Export if looks promising
if (auc > 0.85) {
  export_to_rds_with_metadata(model, "randomforest", data, "quick_model.rds")
}
```

### Example 3: Publication-Ready Analysis

```r
# Use PUBLICATION preset for comprehensive analysis
preset <- apply_preset("publication")

# Load data
data <- read.csv("clinical_trial_data.csv")

# Full preprocessing (according to preset)
# - MICE imputation
# - Outlier analysis
# - Log transform
# - Standardization

# Handle severe imbalance
balanced <- balance_dataset(
  data = data,
  method = "hybrid",  # SMOTE + undersampling
  apply_to = "train"
)

# Train all 6 models with nested CV
models <- train_all_models(
  data = balanced$train,
  models = preset$models,
  validation = "nested_cv",
  cv_folds = 10,
  cv_repetitions = 5
)

# Create stacked ensemble
ensemble <- create_ensemble(
  models = models,
  combination_method = "stacking"
)

# Comprehensive interpretation
interpretation <- explain_model(
  model = ensemble,
  data = balanced$train,
  methods = c("shap", "permutation"),
  output_file = "paper_interpretation.html"
)

# Export for reviewers
export_model(
  model = ensemble,
  data = balanced$train,
  output_dir = "publication_models",
  formats = c("rds", "pmml", "json")
)

# Generate deployment guide
generate_deployment_guide(
  model_type = "ensemble",
  output_dir = "publication_models",
  model_name = "ClinicalTrial_Ensemble_v1"
)
```

---

## Performance Characteristics

### Module Performance

| Module | Overhead | Scaling | Parallelizable |
|--------|----------|---------|----------------|
| **Interpretability** | Medium (SHAP: O(n*m*k)) | Linear with samples | Yes (via fastshap) |
| **Model Export** | Low (I/O bound) | Linear with model size | N/A |
| **SMOTE** | Medium (k-NN search) | O(n log n) | Yes (via parallel) |
| **Presets** | Negligible | Constant | N/A |

### Time Estimates

| Preset | Small Dataset (<500) | Medium (500-5000) | Large (>5000) |
|--------|---------------------|-------------------|---------------|
| Quick | 2-3 min | 5-7 min | 10-15 min |
| Standard | 10-15 min | 15-25 min | 30-45 min |
| Robust | 20-30 min | 30-50 min | 60-90 min |
| Publication | 45-60 min | 60-120 min | 120-180 min |

---

## Summary

### What Was Implemented

✅ **4 NEW MODULES** (~2,500 lines of code)
1. **interpretability.R** (700 lines): SHAP, LIME, Permutation Importance
2. **model_export.R** (550 lines): PMML, RDS, JSON export
3. **smote.R** (650 lines): SMOTE, ADASYN, Hybrid sampling
4. **presets.R** (600 lines): 6 predefined analysis configurations

✅ **COMPREHENSIVE FEATURES**
- Model explainability for regulatory compliance
- Cross-platform deployment capabilities
- Robust handling of imbalanced datasets
- One-click analysis presets

✅ **PRODUCTION READY**
- All modules tested with error handling
- Graceful degradation without optional packages
- Integrated into global.R
- Complete documentation

### Total Application Features

**Priority Improvements (Previously Implemented):**
- ✅ Data validation (6 quality checks)
- ✅ Automatic HTML reporting
- ✅ AutoML system
- ✅ Overfitting detection
- ✅ UI Wizard

**Medium Priority Improvements (Just Implemented):**
- ✅ SHAP/LIME interpretability
- ✅ PMML model export
- ✅ SMOTE imbalance handling
- ✅ Preset configurations

**Total:** 14 major modules, ~9,000 lines of new code

---

## Next Steps (Optional - Low Priority)

If further enhancements are desired:

1. **UI Integration**: Add Shiny UI components for new modules
2. **Interactive Visualizations**: Plotly integration for SHAP plots
3. **Automated Benchmarking**: Compare presets on your datasets
4. **Docker Deployment**: Containerize for production
5. **REST API**: Create API endpoints for model serving

---

## Support & Troubleshooting

### Common Issues

**Issue:** SHAP calculation fails
**Solution:** Install fastshap package or use permutation importance as fallback

**Issue:** PMML export not working
**Solution:** Install r2pmml or pmml package, or use RDS export

**Issue:** SMOTE requires too much memory
**Solution:** Use random oversampling or undersample majority class first

### Getting Help

1. Check TROUBLESHOOTING.md
2. Review module source code for detailed comments
3. Check this documentation for usage examples

---

**End of Documentation**

*Generated: 2025-12-26*
*Version: 2.1.0*
*Medium Priority Improvements - COMPLETE*
