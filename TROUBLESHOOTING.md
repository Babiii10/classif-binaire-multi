# Guide de Dépannage

## 🔧 Problèmes Courants et Solutions

### 1. Erreur au démarrage : "Error in parse(file...)"

**Symptôme** : L'application ne démarre pas, erreur de parsing dans server.R

**Causes possibles** :
- Virgule manquante dans le code
- Problème d'encodage (Windows vs Unix)

**Solutions** :
```r
# Vérifier que vous avez la dernière version
git pull origin claude/review-app-classification-3gX07

# Si le problème persiste, vérifier l'encodage
# Dans RStudio : File > Reopen with Encoding > UTF-8
```

---

### 2. Modules ne se chargent pas

**Symptôme** : Messages d'avertissement "Could not load config.R" ou similaires

**Cause** : Packages optionnels manquants

**Solution** :
```r
# Installer toutes les dépendances
source("install_dependencies.R")

# Ou installer manuellement les packages manquants
install.packages(c("digest", "doParallel", "foreach", "markdown", "jsonlite"))
```

**Note** : L'application fonctionnera même sans ces packages, mais certaines fonctionnalités seront limitées.

---

### 3. Erreur "package 'digest' not found"

**Symptôme** : Erreur lors du chargement du système de cache

**Solution** :
```r
# Option 1 : Installer digest
install.packages("digest")

# Option 2 : Désactiver le cache (dans config.R)
PERFORMANCE$enable_cache <- FALSE
```

---

### 4. Problème de performance (lenteur)

**Symptôme** : Grid search ou bootstrap très lents

**Solution 1** : Activer la parallélisation
```r
# Installer les packages nécessaires
install.packages(c("doParallel", "foreach"))

# Vérifier dans config.R que c'est activé
PERFORMANCE$enable_parallel <- TRUE
PERFORMANCE$n_cores <- 4  # Ajuster selon votre machine
```

**Solution 2** : Activer le cache
```r
install.packages("digest")

# Dans config.R
PERFORMANCE$enable_cache <- TRUE
```

---

### 5. "Clustering + ElasticNet only for binary"

**Symptôme** : Erreur lors de l'utilisation de clustEnet en multi-classe

**Cause** : Version ancienne du code

**Solution** :
```r
# Mettre à jour vers la dernière version
git pull origin claude/review-app-classification-3gX07

# Vérifier que global.R contient la version multi-classe
# Ligne ~1310 devrait dire "Support both binary and multi-class"
```

---

### 6. Problème avec lightgbm

**Symptôme** : Erreur lors de l'utilisation du modèle LightGBM

**Cause** : Package lightgbm nécessite installation spéciale

**Solution** :
```r
# Installation depuis GitHub
devtools::install_github("microsoft/LightGBM", subdir = "R-package")

# Si échec, utiliser un autre modèle (XGBoost est similaire)
```

---

### 7. Tooltips ne s'affichent pas

**Symptôme** : Pas de tooltips interactifs dans l'UI

**Cause** : Package bslib manquant ou tooltips désactivés

**Solution** :
```r
# Installer bslib
install.packages("bslib")

# Vérifier dans config.R
UI_CONFIG$enable_tooltips <- TRUE
```

---

### 8. Erreur de mémoire (Out of Memory)

**Symptôme** : "Cannot allocate vector of size..." ou crash

**Solution 1** : Limiter la taille du cache
```r
# Dans cache.R, modifier la ligne ~124
max_size <- 100 * 1024^2  # 100 MB au lieu de 500 MB
```

**Solution 2** : Réduire le nombre de cœurs parallèles
```r
# Dans config.R
PERFORMANCE$n_cores <- 2  # Au lieu de détection automatique
```

**Solution 3** : Filtrer plus agressivement les données
```r
# Dans l'UI, augmenter le % minimum de valeurs
# Ex: 80% au lieu de 50%
```

---

### 9. Problème d'import de données

**Symptôme** : Erreur lors du chargement CSV ou Excel

**Solutions** :

**Pour CSV** :
- Vérifier le séparateur (virgule, point-virgule, tab)
- Vérifier le caractère décimal (. ou ,)
- Vérifier l'encodage (UTF-8 recommandé)

**Pour Excel** :
- Vérifier le numéro de feuille
- Vérifier les lignes à sauter
- S'assurer que le fichier n'est pas ouvert dans Excel

**Structure attendue** :
```
Nom_Echantillon  | Classe    | Variable1 | Variable2 | ...
Sample1          | Controle  | 1.23      | 4.56      | ...
Sample2          | Malade    | 2.34      | 5.67      | ...
```

---

### 10. Modèle ne converge pas

**Symptôme** : Avertissements de convergence avec ElasticNet/XGBoost

**Solutions** :

**Pour ElasticNet** :
```r
# Augmenter nlambda
DEFAULT_PARAMS$regularization$nlambda <- 200

# Ou ajuster alpha
DEFAULT_PARAMS$regularization$alpha_default <- 0.5
```

**Pour XGBoost** :
```r
# Réduire learning rate
DEFAULT_PARAMS$xgboost$eta_default <- 0.1

# Augmenter nrounds
DEFAULT_PARAMS$xgboost$nrounds_default <- 500
```

---

## 🆘 Réinitialisation Complète

Si rien ne fonctionne, réinitialiser l'environnement :

```r
# 1. Nettoyer l'environnement R
rm(list = ls())
gc()

# 2. Supprimer le cache
unlink(".cache", recursive = TRUE)

# 3. Supprimer la config personnalisée
file.remove("custom_config.json")

# 4. Réinstaller les dépendances
source("install_dependencies.R")

# 5. Redémarrer R et relancer l'app
.rs.restartR()  # Dans RStudio
shiny::runApp()
```

---

## 📋 Checklist de Diagnostic

Avant de demander de l'aide, vérifier :

- [ ] Version de R >= 4.0.0 (`R.version.string`)
- [ ] Packages core installés (`source("install_dependencies.R")`)
- [ ] Dernière version du code (`git pull`)
- [ ] Fichiers de données au bon format
- [ ] Pas de fichier corrompu dans `.cache/`
- [ ] Messages d'erreur complets copiés
- [ ] Logs de chargement des modules

---

## 📞 Obtenir de l'Aide

Si le problème persiste :

1. **Copier les messages d'erreur complets**
2. **Noter la configuration** : OS, version R, packages installés
3. **Décrire les étapes** qui mènent à l'erreur
4. **Joindre les logs** (si disponibles)

---

## 🔍 Logs de Diagnostic

Pour activer les logs détaillés :

```r
# Dans global.R, au début
options(warn = 2)  # Convertir warnings en erreurs
options(error = traceback)  # Stack trace complet

# Lancer l'app en mode debug
options(shiny.trace = TRUE)
shiny::runApp()
```

---

## ✅ Tests de Validation

Pour vérifier que tout fonctionne :

```r
# Test 1 : Chargement des modules
source("global.R")
# Devrait afficher : "✓ Configuration system loaded", etc.

# Test 2 : Vérifier les fonctions principales
exists("clustEnetSelection")  # TRUE
exists("create_ensemble")      # TRUE
exists("cached_select_data")   # TRUE

# Test 3 : Vérifier la configuration
print_config()

# Test 4 : Vérifier le cache
cache_stats()

# Test 5 : Test simple
# Charger un petit jeu de données et faire une analyse rapide
```

---

**Version** : 2.0.0
**Dernière mise à jour** : Janvier 2025
