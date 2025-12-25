##########################
# Installation Script for Dependencies
# Run this script to install all required and optional packages
##########################

cat("===== Installing Dependencies for Classification App =====\n\n")

# Core packages (required)
core_packages <- c(
  "shiny",
  "shinythemes",
  "bslib",
  "zoo",
  "missMDA",
  "ggplot2",
  "stats",
  "tidyr",
  "e1071",
  "pROC",
  "devtools",
  "readxl",
  "superml",
  "reshape2",
  "xlsx",
  "randomForest",
  "missForest",
  "Hmisc",
  "corrplot",
  "penalizedSVM",
  "DT",
  "shinycssloaders",
  "writexl",
  "glmnet",
  "survival",
  "xgboost",
  "lightgbm",
  "class"
)

# New optional packages for enhanced features
optional_packages <- c(
  "digest",        # For caching system
  "doParallel",    # For parallel computing
  "foreach",       # For parallel computing
  "markdown",      # For tooltips formatting
  "jsonlite"       # For config import/export
)

# Function to install a package if not present
install_if_missing <- function(pkg, type = "required") {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("[%s] Installing %s...\n", type, pkg))
    tryCatch({
      install.packages(pkg, dependencies = TRUE)
      cat(sprintf("  ✓ %s installed successfully\n", pkg))
    }, error = function(e) {
      cat(sprintf("  ✗ Failed to install %s: %s\n", pkg, e$message))
      if (type == "required") {
        stop(sprintf("Critical package %s could not be installed", pkg))
      }
    })
  } else {
    cat(sprintf("  ✓ %s already installed\n", pkg))
  }
}

# Install core packages
cat("\n--- Installing CORE packages (required) ---\n")
for (pkg in core_packages) {
  install_if_missing(pkg, "required")
}

# Install optional packages
cat("\n--- Installing OPTIONAL packages (for enhanced features) ---\n")
cat("Note: App will work without these, but some features may be limited\n\n")
for (pkg in optional_packages) {
  install_if_missing(pkg, "optional")
}

# Special handling for lightgbm (may require special installation)
cat("\n--- Special packages ---\n")
if (!requireNamespace("lightgbm", quietly = TRUE)) {
  cat("LightGBM requires special installation. Attempting...\n")
  tryCatch({
    # Try to install from GitHub
    if (requireNamespace("devtools", quietly = TRUE)) {
      devtools::install_github("microsoft/LightGBM", subdir = "R-package")
      cat("  ✓ LightGBM installed from GitHub\n")
    } else {
      cat("  ! LightGBM installation skipped (devtools not available)\n")
      cat("  To install manually: devtools::install_github('microsoft/LightGBM', subdir = 'R-package')\n")
    }
  }, error = function(e) {
    cat("  ! LightGBM installation failed (not critical)\n")
    cat("  The app will work without LightGBM model\n")
  })
}

# Verify installation
cat("\n\n===== Verification =====\n")

core_installed <- sapply(core_packages, requireNamespace, quietly = TRUE)
optional_installed <- sapply(optional_packages, requireNamespace, quietly = TRUE)

cat(sprintf("\nCore packages: %d/%d installed\n",
            sum(core_installed), length(core_packages)))

if (sum(!core_installed) > 0) {
  cat("Missing core packages:\n")
  for (pkg in core_packages[!core_installed]) {
    cat(sprintf("  - %s\n", pkg))
  }
}

cat(sprintf("\nOptional packages: %d/%d installed\n",
            sum(optional_installed), length(optional_packages)))

if (sum(!optional_installed) > 0) {
  cat("Missing optional packages (features will be limited):\n")
  for (pkg in optional_packages[!optional_installed]) {
    cat(sprintf("  - %s\n", pkg))
  }
}

# Summary
cat("\n\n===== Installation Summary =====\n")

if (sum(!core_installed) == 0) {
  cat("✓ All core packages installed successfully!\n")
  cat("✓ The app is ready to run\n\n")
  cat("To start the app, run:\n")
  cat("  shiny::runApp()\n\n")

  if (sum(optional_installed) == length(optional_packages)) {
    cat("✓ All optional packages installed - all features enabled!\n")
  } else {
    cat("Note: Some optional packages missing. The following features may be limited:\n")
    if (!optional_installed["digest"]) {
      cat("  - Caching system (will use simple fallback)\n")
    }
    if (!optional_installed["doParallel"] || !optional_installed["foreach"]) {
      cat("  - Parallel computing (will run sequentially)\n")
    }
    if (!optional_installed["markdown"]) {
      cat("  - Tooltip formatting (will use plain text)\n")
    }
    if (!optional_installed["jsonlite"]) {
      cat("  - Config import/export (manual editing only)\n")
    }
  }

} else {
  cat("✗ Some core packages are missing\n")
  cat("Please install missing packages before running the app\n")
}

cat("\n===== Installation Complete =====\n")
