##########################
# Interactive Help and Tooltips System
# Provides contextual documentation and tooltips
##########################

##########################
# Tooltip Definitions
##########################

# Define tooltips for all UI elements
TOOLTIPS <- list(
  # Data Import
  filetype = "Format du fichier de données : CSV (délimité par virgule/point-virgule) ou Excel (XLSX)",

  learningfile = "Fichier principal pour l'entraînement du modèle. Doit contenir les noms des échantillons en première colonne, les classes en deuxième colonne, et les variables en colonnes suivantes.",

  validationfile = "Fichier optionnel pour valider le modèle sur des données indépendantes. Même structure que le fichier d'apprentissage.",

  dec = "Caractère utilisé pour le séparateur décimal dans les fichiers CSV (généralement . ou ,)",

  sep = "Caractère de séparation des colonnes dans les fichiers CSV",

  NAstring = "Chaîne de caractères représentant les valeurs manquantes (ex: NA, N/A, null)",

  transpose = "Inverser lignes et colonnes si vos échantillons sont en colonnes au lieu de lignes",

  zeroegalNA = "Traiter les valeurs zéro comme des valeurs manquantes (utile pour les données omiques)",

  # Data Selection
  prctvalues = "Pourcentage minimum de valeurs non-manquantes requis pour conserver une variable. Augmenter ce seuil réduit le nombre de variables mais améliore leur qualité.",

  selectmethod = paste(
    "Méthode de sélection des variables basée sur les valeurs manquantes :",
    "\n• Tous les échantillons : la variable doit avoir x% de valeurs dans l'ensemble complet",
    "\n• Chaque groupe : chaque classe doit avoir x% de valeurs",
    "\n• Au moins un groupe : au moins une classe doit avoir x% de valeurs"
  ),

  NAstructure = "Activer le test de structure des NA : identifie les variables dont les valeurs manquantes sont significativement différentes entre les groupes (peut indiquer une présence/absence biologique)",

  thresholdNAstructure = "Seuil de p-value pour le test de structure des NA. Plus le seuil est bas, plus la sélection est stricte.",

  structdata = paste(
    "Rechercher la structure des NA dans :",
    "\n• Toutes les données : test sur l'ensemble complet",
    "\n• Données sélectionnées : test uniquement sur les variables pré-sélectionnées"
  ),

  # Data Transformation
  rempNA = paste(
    "Méthode de remplacement des valeurs manquantes :",
    "\n• Zéro : remplace par 0",
    "\n• Moyenne de la cohorte : remplace par la moyenne globale",
    "\n• Moyenne par groupe : remplace par la moyenne de chaque classe",
    "\n• PCA : imputation par analyse en composantes principales (recommandé)",
    "\n• Random Forest : imputation par forêt aléatoire (plus lent mais précis)"
  ),

  log = "Transformation logarithmique des données pour réduire l'asymétrie et stabiliser la variance",

  logtype = "Type de logarithme : ln (naturel), log10 (base 10), ou log2 (base 2, utile pour fold-changes)",

  standardization = "Normalisation par division par l'écart-type quadratique moyen (utile quand les variables ont des échelles différentes)",

  arcsin = "Transformation arcsinus : rescale les données entre 0-1 puis applique arcsin (utile pour les proportions)",

  # Statistical Tests
  test = paste(
    "Méthode de sélection de variables :",
    "\n\n**Tests univariés** (testent chaque variable indépendamment) :",
    "\n• Wilcoxon : test non-paramétrique (sans hypothèse de normalité)",
    "\n• Student : test paramétrique (assume normalité des données)",
    "\n\n**Méthodes multivariées** (considèrent les interactions) :",
    "\n• Lasso : régularisation L1, sélection parcimonieuse",
    "\n• ElasticNet : combinaison L1+L2, équilibre entre Lasso et Ridge",
    "\n• Ridge : régularisation L2, réduit mais ne supprime pas",
    "\n• Clustering + ElasticNet : clustering des variables corrélées puis sélection par bootstrap ElasticNet (robuste, recommandé)"
  ),

  thresholdFC = "Seuil de Fold Change (rapport des moyennes entre groupes). 0 = pas de filtrage, 1 = doublement minimum, 2 = quadruplement minimum",

  thresholdpv = "Seuil de p-value pour la significativité statistique. Valeurs typiques : 0.05 (5%), 0.01 (1%), 0.001 (0.1%)",

  adjustpv = "Correction de Benjamini-Hochberg pour tests multiples : réduit les faux positifs quand on teste beaucoup de variables simultanément",

  # Clustering + ElasticNet
  nclusters = "Nombre de clusters pour regrouper les variables corrélées. Augmenter ce nombre permet une sélection plus fine mais augmente le temps de calcul.",

  nbootstrap = "Nombre d'itérations bootstrap pour la robustesse de la sélection. Plus élevé = plus robuste mais plus lent. Recommandé : 500-1000",

  alphaclustenet = "Paramètre de mélange ElasticNet : 0=Ridge (conserve toutes variables), 1=Lasso (sélection parcimonieuse), 0.5=équilibre (recommandé)",

  minselectionfreq = "Fréquence minimum de sélection dans les bootstraps. 0.5 = la variable doit être sélectionnée dans au moins 50% des itérations",

  preprocessclustenet = "Pré-filtrer les variables à faible variance ou faible fréquence avant le clustering (recommandé)",

  # Models
  model = paste(
    "Type de modèle de classification :",
    "\n• Random Forest : robuste, peu de paramètres, gérer les non-linéarités",
    "\n• SVM : puissant, efficace en haute dimension",
    "\n• ElasticNet : régularisation, interprétable, sélection de variables",
    "\n• XGBoost : gradient boosting performant, optimisation avancée",
    "\n• KNN : simple, non-paramétrique, sensible à l'échelle",
    "\n• Naive Bayes : rapide, probabiliste, assume indépendance",
    "\n\nChaque modèle supporte la classification binaire et multi-classe"
  ),

  thresholdmodel = "Seuil de classification pour les modèles probabilistes. 0 = décision par défaut, >0 favorise classe positive, <0 favorise classe négative",

  fs = "Sélection de variables par validation croisée : teste chaque variable individuellement pour ne garder que les plus informatives. Améliore la performance mais augmente le temps de calcul.",

  # Random Forest
  ntreerf = "Nombre d'arbres dans la forêt. Plus élevé = plus stable mais plus lent. Recommandé : 500-1000",

  mtryrf = "Nombre de variables testées à chaque division. Par défaut : racine carrée du nombre total de variables",

  tuning_method_rf = paste(
    "Méthode d'optimisation des hyperparamètres :",
    "\n• Manuel : vous spécifiez mtry",
    "\n• tuneRF : optimise mtry automatiquement par validation croisée",
    "\n• GridSearchCV : recherche exhaustive sur grille (mtry, ntree, nodesize)"
  ),

  # SVM
  costsvm = "Paramètre C : compromis entre marge maximale et erreurs de classification. Plus grand = tolère moins d'erreurs mais risque de surapprentissage",

  gammasvm = "Paramètre gamma : inverse du rayon d'influence. Plus grand = frontière de décision plus complexe",

  kernelsvm = paste(
    "Type de noyau SVM :",
    "\n• Radial (RBF) : polyvalent, recommandé par défaut",
    "\n• Linear : relations linéaires, rapide",
    "\n• Polynomial : interactions polynomiales",
    "\n• Sigmoid : similaire aux réseaux de neurones"
  ),

  autotunesvm = "Optimisation automatique de C et gamma par recherche sur grille avec validation croisée (recommandé)",

  # XGBoost
  nroundsxgb = "Nombre d'itérations de boosting. Plus élevé = modèle plus complexe mais risque de surapprentissage",

  maxdepthxgb = "Profondeur maximale des arbres. Plus profond = capture plus de complexité mais risque de surapprentissage. Recommandé : 3-10",

  etaxgb = "Taux d'apprentissage (learning rate) : réduit l'influence de chaque arbre. Plus petit = convergence plus lente mais plus robuste. Recommandé : 0.01-0.3",

  tuning_method_xgb = paste(
    "Méthode d'optimisation :",
    "\n• Manuel : vous spécifiez tous les paramètres",
    "\n• CV (xgb.cv) : optimise nrounds par validation croisée",
    "\n• GridSearchCV : recherche exhaustive multi-paramètres"
  ),

  # ElasticNet
  alphamodel = "Paramètre de mélange : 0=Ridge (L2), 1=Lasso (L1), entre 0-1=ElasticNet (combinaison L1+L2)",

  lambdamodel = "Force de régularisation : plus grand = plus de pénalisation (coefficients plus petits). Laisser vide pour sélection automatique par CV",

  tuning_method_en = paste(
    "Méthode d'optimisation :",
    "\n• CV traditionnel (cv.glmnet) : optimise lambda pour alpha fixé",
    "\n• GridSearchCV : optimise conjointement alpha et lambda"
  ),

  # KNN
  kneighbors = "Nombre de voisins (k) : plus petit = frontière plus complexe mais sensible au bruit, plus grand = frontière plus lisse. Recommandé : 3-15",

  tuning_method_knn = paste(
    "Méthode d'optimisation :",
    "\n• Manuel : vous spécifiez k",
    "\n• CV traditionnelle : teste différentes valeurs de k"
  ),

  # Naive Bayes
  tuning_method_nb = paste(
    "Méthode d'optimisation :",
    "\n• Pas de tuning : laplace=0 (par défaut)",
    "\n• GridSearchCV : optimise le paramètre de lissage Laplace"
  ),

  # Threshold optimization
  threshold_method_test = paste(
    "Méthode d'optimisation du seuil de classification :",
    "\n• Fixe : 0.5 pour modèles probabilistes, 0 pour SVM",
    "\n• Youden : maximise sensibilité + spécificité (équilibre)",
    "\n• Équiprobabilité : minimise faux positifs = faux négatifs (taux d'erreur égal)",
    "\n\nNote : le seuil est calculé sur TRAIN et appliqué sur validation"
  ),

  tuning_method_test = paste(
    "Optimisation automatique des hyperparamètres :",
    "\n• Paramètres par défaut : rapide, utilise valeurs standard",
    "\n• Tuning automatique : optimise par CV (tune.svm, tuneRF, cv.glmnet, xgb.cv, etc.)",
    "\n\nLe tuning automatique améliore les performances mais augmente le temps de calcul"
  ),

  # Advanced
  adjustval = "Ré-entraîner le modèle sur les données de validation pour évaluer la robustesse",

  plotscoremodel = "Type de visualisation des scores : boxplot (distribution) ou points (valeurs individuelles)"
)

##########################
# Help Text Definitions
##########################

# Define contextual help messages
HELP_TEXT <- list(
  import_data = paste(
    "**Import de données**",
    "\n\nStructure attendue :",
    "\n• Première colonne : noms des échantillons (identifiants uniques)",
    "\n• Deuxième colonne : classes/groupes (ex: Contrôle, Malade)",
    "\n• Colonnes suivantes : variables/features mesurées",
    "\n\nFormats supportés : CSV (avec séparateur personnalisable) et Excel (XLSX)",
    "\n\nConseils :",
    "\n• Vérifiez que la structure est correcte dans l'aperçu",
    "\n• Les valeurs manquantes doivent être cohérentes (NA, vide, ou personnalisé)",
    "\n• Pour les données omiques, pensez à utiliser 'Transposer' si nécessaire"
  ),

  select_data = paste(
    "**Sélection des variables**",
    "\n\nObjectif : réduire le nombre de variables en éliminant celles avec trop de valeurs manquantes",
    "\n\nÉtapes recommandées :",
    "\n1. Définir le % minimum de valeurs (ex: 70% pour garder variables avec ≥70% de données)",
    "\n2. Choisir la méthode de sélection selon vos objectifs",
    "\n3. (Optionnel) Activer le test de structure des NA si pertinent biologiquement",
    "\n\nLe graphique heatmap montre les valeurs manquantes en blanc"
  ),

  transform_data = paste(
    "**Transformation des données**",
    "\n\nÉtapes recommandées :",
    "\n1. Remplir les NA (PCA recommandé pour données omiques)",
    "\n2. Transformation log si données asymétriques ou avec grandes variations d'échelle",
    "\n3. Standardisation si variables d'échelles très différentes",
    "\n\nLe MDS (Multi-Dimensional Scaling) visualise la séparation entre groupes"
  ),

  statistics = paste(
    "**Tests statistiques**",
    "\n\nChoix de la méthode :",
    "\n• **Tests univariés** (Wilcoxon/Student) : simples, interprétables, mais ignorent corrélations",
    "\n• **Méthodes multivariées** (Lasso/ElasticNet/Ridge) : considèrent interactions, plus robustes",
    "\n• **Clustering + ElasticNet** : méthode la plus robuste, recommandée pour haute dimension",
    "\n\nPour classification multi-classe : toutes les méthodes sont supportées !"
  ),

  model_training = paste(
    "**Entraînement du modèle**",
    "\n\nChoix du modèle selon vos besoins :",
    "\n• **Random Forest** : polyvalent, robuste, peu de tuning",
    "\n• **SVM** : puissant, efficace en haute dimension",
    "\n• **ElasticNet** : interprétable, sélection de variables intégrée",
    "\n• **XGBoost** : très performant, nécessite tuning",
    "\n• **KNN** : simple, bon pour données denses",
    "\n• **Naive Bayes** : rapide, probabiliste",
    "\n\nTous supportent binaire ET multi-classe automatiquement !",
    "\n\nOptions avancées :",
    "\n• Tuning automatique : recommandé pour optimiser les performances",
    "\n• Feature selection par CV : améliore robustesse mais augmente temps",
    "\n• Threshold optimization : choisir le seuil selon votre objectif (équilibre vs minimiser FP/FN)"
  ),

  multiclass_support = paste(
    "**Support Multi-classe**",
    "\n\nL'application détecte automatiquement le nombre de classes et adapte :",
    "\n\n✅ Tests statistiques :",
    "\n• Wilcoxon → Kruskal-Wallis",
    "\n• Student → ANOVA",
    "\n• Lasso/ElasticNet/Ridge → multinomial regression",
    "\n• **Nouveau !** Clustering + ElasticNet → support multi-classe",
    "\n\n✅ Modèles :",
    "\n• Tous les modèles supportent automatiquement le multi-classe",
    "\n• Métriques adaptées : AUC One-vs-Rest, accuracy globale, métriques par classe",
    "\n\n✅ Visualisations :",
    "\n• ROC curves par classe (One-vs-Rest)",
    "\n• Boxplots des probabilités prédites",
    "\n• Matrice de confusion multi-classe"
  ),

  ensemble_methods = paste(
    "**Méthodes d'ensemble (Nouveau !)**",
    "\n\nCombinez plusieurs modèles pour améliorer les performances :",
    "\n\n• **Voting** : vote majoritaire (classification)",
    "\n• **Averaging** : moyenne des probabilités",
    "\n• **Weighted** : moyenne pondérée (poids optimisés automatiquement)",
    "\n• **Stacking** : méta-modèle entraîné sur prédictions",
    "\n\nActivation : voir configuration dans config.R"
  ),

  performance_optimization = paste(
    "**Optimisation des performances (Nouveau !)**",
    "\n\n🚀 **Calculs parallèles** :",
    "\n• Utilisation automatique de plusieurs cœurs CPU",
    "\n• Accélère : grid search, bootstrap, test all models",
    "\n• Configuration : voir PERFORMANCE dans config.R",
    "\n\n💾 **Système de cache** :",
    "\n• Évite recalculs inutiles des transformations de données",
    "\n• Cache automatique avec expiration configurable",
    "\n• Persistance entre sessions",
    "\n\nRésultat : gain de temps significatif sur analyses répétées !"
  ),

  configuration = paste(
    "**Configuration avancée**",
    "\n\nFichier config.R permet de personnaliser :",
    "\n\n• Paramètres par défaut de chaque modèle",
    "\n• Paramètres de performance (parallélisme, cache)",
    "\n• Configuration d'ensemble",
    "\n• Options d'interface utilisateur",
    "\n\nPour personnaliser : créer custom_config.json",
    "\nPour réinitialiser : supprimer custom_config.json"
  )
)

##########################
# Tooltip Helper Functions
##########################

# Get tooltip for a specific element
get_tooltip <- function(element_id) {
  if (element_id %in% names(TOOLTIPS)) {
    return(TOOLTIPS[[element_id]])
  }
  return(NULL)
}

# Get help text for a section
get_help_text <- function(section_id) {
  if (section_id %in% names(HELP_TEXT)) {
    return(HELP_TEXT[[section_id]])
  }
  return(NULL)
}

# Create tooltip HTML
create_tooltip_html <- function(element_id, label) {
  tooltip_text <- get_tooltip(element_id)

  if (is.null(tooltip_text)) {
    return(label)
  }

  if (UI_CONFIG$enable_tooltips) {
    # Use bslib tooltip
    return(bslib::tooltip(
      label,
      tooltip_text,
      placement = UI_CONFIG$tooltip_placement
    ))
  } else {
    return(label)
  }
}

# Create help panel
create_help_panel <- function(section_id, style = "info") {
  help_text <- get_help_text(section_id)

  if (is.null(help_text)) {
    return(NULL)
  }

  shiny::wellPanel(
    style = paste0("background-color: ",
                   switch(style,
                          "info" = "#d9edf7",
                          "success" = "#dff0d8",
                          "warning" = "#fcf8e3",
                          "danger" = "#f2dede",
                          "#f5f5f5"),
                   "; border-color: ",
                   switch(style,
                          "info" = "#bce8f1",
                          "success" = "#d6e9c6",
                          "warning" = "#faebcc",
                          "danger" = "#ebccd1",
                          "#ddd"),
                   ";"),
    shiny::HTML(markdown::markdownToHTML(text = help_text, fragment.only = TRUE))
  )
}

# Create collapsible help section
create_collapsible_help <- function(section_id, title = "Aide", icon = "question-circle") {
  help_text <- get_help_text(section_id)

  if (is.null(help_text)) {
    return(NULL)
  }

  tagList(
    actionButton(
      paste0("toggle_help_", section_id),
      tagList(icon(icon), title),
      class = "btn-info btn-sm",
      style = "margin-bottom: 10px;"
    ),
    conditionalPanel(
      condition = paste0("input.toggle_help_", section_id, " % 2 == 1"),
      create_help_panel(section_id)
    )
  )
}

##########################
# Feature Highlight System
##########################

# Highlight new features
NEW_FEATURES <- list(
  multiclass_clustenet = list(
    title = "🎉 Nouveau : Clustering + ElasticNet pour Multi-classe",
    description = "La méthode Clustering + ElasticNet supporte maintenant la classification multi-classe ! Utilise Kruskal-Wallis pour sélection par cluster et régression multinomiale pour le bootstrap.",
    version = "2.0.0",
    date = "2025-01-15"
  ),

  ensemble_methods = list(
    title = "🎉 Nouveau : Méthodes d'ensemble",
    description = "Combinez plusieurs modèles (voting, averaging, weighted, stacking) pour améliorer les performances prédictives.",
    version = "2.0.0",
    date = "2025-01-15"
  ),

  parallel_computing = list(
    title = "🚀 Nouveau : Calculs parallèles",
    description = "Utilisation automatique de plusieurs cœurs CPU pour accélérer grid search, bootstrap et test all models.",
    version = "2.0.0",
    date = "2025-01-15"
  ),

  caching_system = list(
    title = "💾 Nouveau : Système de cache",
    description = "Les transformations de données sont mises en cache pour éviter les recalculs inutiles et accélérer les analyses.",
    version = "2.0.0",
    date = "2025-01-15"
  ),

  configurable_parameters = list(
    title = "⚙️ Nouveau : Paramètres configurables",
    description = "Tous les paramètres de modèles sont maintenant centralisés dans config.R et personnalisables via custom_config.json.",
    version = "2.0.0",
    date = "2025-01-15"
  )
)

# Create new features panel
create_new_features_panel <- function() {
  if (length(NEW_FEATURES) == 0) {
    return(NULL)
  }

  feature_items <- lapply(NEW_FEATURES, function(feature) {
    tags$div(
      style = "margin-bottom: 15px; padding: 10px; background-color: #fff3cd; border-left: 4px solid #ffc107; border-radius: 4px;",
      tags$h5(feature$title, style = "margin-top: 0; color: #856404;"),
      tags$p(feature$description, style = "margin-bottom: 5px;"),
      tags$small(
        paste("Version", feature$version, "•", feature$date),
        style = "color: #856404; font-style: italic;"
      )
    )
  })

  wellPanel(
    style = "background-color: #fffbf0; border: 2px solid #ffc107;",
    h4("✨ Nouveautés", style = "margin-top: 0;"),
    do.call(tagList, feature_items)
  )
}

##########################
# Quick Start Guide
##########################

QUICK_START_STEPS <- list(
  list(
    step = 1,
    title = "Importer les données",
    description = "Charger le fichier d'apprentissage (obligatoire) et optionnellement le fichier de validation",
    icon = "upload"
  ),
  list(
    step = 2,
    title = "Sélectionner les variables",
    description = "Filtrer les variables avec trop de valeurs manquantes",
    icon = "filter"
  ),
  list(
    step = 3,
    title = "Transformer les données",
    description = "Remplir les NA, appliquer transformation log si nécessaire",
    icon = "magic"
  ),
  list(
    step = 4,
    title = "Tests statistiques",
    description = "Sélectionner les variables discriminantes (Wilcoxon, ElasticNet, Clustering + ElasticNet, etc.)",
    icon = "calculator"
  ),
  list(
    step = 5,
    title = "Entraîner le modèle",
    description = "Choisir un modèle et optimiser les hyperparamètres",
    icon = "cogs"
  ),
  list(
    step = 6,
    title = "Évaluer et exporter",
    description = "Vérifier les performances (AUC, accuracy, courbe ROC) et exporter les résultats",
    icon = "check-circle"
  )
)

create_quick_start_guide <- function() {
  step_items <- lapply(QUICK_START_STEPS, function(step) {
    tags$div(
      style = "display: flex; align-items: start; margin-bottom: 15px;",
      tags$div(
        style = "flex-shrink: 0; width: 40px; height: 40px; background-color: #007bff; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 15px;",
        step$step
      ),
      tags$div(
        style = "flex-grow: 1;",
        tags$h5(
          icon(step$icon),
          step$title,
          style = "margin: 0 0 5px 0;"
        ),
        tags$p(
          step$description,
          style = "margin: 0; color: #666;"
        )
      )
    )
  })

  wellPanel(
    h4("🚀 Guide de démarrage rapide", style = "margin-top: 0;"),
    do.call(tagList, step_items)
  )
}

##########################
# Initialize tooltips
##########################

message("Tooltip and help system initialized")
message(paste("Total tooltips defined:", length(TOOLTIPS)))
message(paste("Total help sections defined:", length(HELP_TEXT)))
message(paste("New features to highlight:", length(NEW_FEATURES)))
