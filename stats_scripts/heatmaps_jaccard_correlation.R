
# =============================================================================
# Heatmaps : Distance de Jaccard entre sites & Corrélations entre taxons
# =============================================================================

# --- 1. Packages nécessaires -------------------------------------------------
packages <- c("vegan", "pheatmap", "RColorBrewer")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(packages, install_if_missing))

library(vegan)
library(pheatmap)
library(RColorBrewer)

# --- 2. Chargement des données -----------------------------------------------
# Remplacez le chemin par l'emplacement de votre fichier

setwd("/home/karrouchi/Documents/PTUT_analyse_figure")
data=read.csv("matrice_totale.csv", header=T, stringsAsFactors = T)

#définir les noms de lignes à partir de la colonne Echantillon
rownames(data) <- data$Echantillon
data <- data[, -1]   
# supprimer la colonne Echantillon maintenant qu'elle est en rownames
# --- 3. Conversion en présence/absence pour Jaccard --------------------------
# Jaccard est une mesure binaire : 1 si taxon présent, 0 sinon
mat_pa <- decostand(data[,-1], method = "pa")   # présence/absence via vegan


# --- 4. Calcul de la distance de Jaccard entre sites -------------------------
dist_jaccard <- vegdist(mat_pa, method = "jaccard")
mat_jaccard  <- as.matrix(dist_jaccard)

cat("Matrice de distance Jaccard (aperçu 5x5) :\n")
print(round(mat_jaccard[1:5, 1:5], 3))

# --- 5. Heatmap — Distance de Jaccard entre sites ----------------------------

# Palette de couleurs (0 = identiques → bleu, 1 = totalement différents → rouge)
pal_jaccard <- colorRampPalette(brewer.pal(9, "YlOrRd"))(100)

# Annotation des lignes/colonnes avec une période chronologique
# Extraire la période à partir du nom du site
get_period <- function(site_name) {
  ifelse(grepl("Meso",     site_name), "Mesolithic",
         ifelse(grepl("Neo",      site_name), "Neolithic",
                ifelse(grepl("Bronze",   site_name), "Bronze Age",
                       ifelse(grepl("Iron",     site_name), "Iron Age",
                              ifelse(grepl("Roman",    site_name), "Roman Empire",
                                     ifelse(grepl("Post_Mid", site_name), "Post Middle Ages",
                                            ifelse(grepl("Mid_Age",  site_name), "Middle Ages",
                                                   "Other")))))))
}

periods <- data.frame(
  Période = get_period(rownames(data)),
  row.names = rownames(data)
)

period_colors <- list(
  Période = c(
    "Mesolithic"    = "#4575b4",
    "Neolithic"     = "#91bfdb",
    "Bronze Age"   = "#e0f3f8",
    "Iron Age"      = "#fee090",
    "Roman Empire" = "#fc8d59",
    "Middle Ages"       = "#d73027",
    "Post Middle Ages"  = "#a50026",
    "Other"           = "#cccccc"
  )
)

# Export PNG
png("heatmap_jaccard_sites_average.png", width = 1400, height = 1200, res = 150)

pheatmap(
  mat_jaccard,
  color             = pal_jaccard,
  clustering_method = "average",
  annotation_row    = periods,
  annotation_col    = periods,
  annotation_colors = period_colors,
  main              = "Jaccard distance between each samples (presence/missing taxa)",
  fontsize          = 8,
  fontsize_row      = 7,
  fontsize_col      = 7,
  angle_col         = 45,
  border_color      = NA,
  legend_breaks     = seq(0, 1, by = 0.2),
  legend_labels     = seq(0, 1, by = 0.2)
)

dev.off()
cat("→ heatmap_jaccard_sites_average.png exportée\n")

# --- 6. Calcul des corrélations entre taxons ---------------------------------
# On travaille sur la matrice d'abondance originale : sites × taxons
# Corrélation de Spearman (robuste aux distributions non-normales)
#PS: dans cette version, nous allons 
cor_taxons <- cor(data[,-1], method = "spearman", use = "pairwise.complete.obs")

cat("\nMatrice de corrélation Spearman entre taxons (aperçu 4x4) :\n")
print(round(cor_taxons[1:4, 1:4], 3))

# --- 7. Heatmap — Corrélations entre taxons (pearson)----------------------------------

# Palette divergente : bleu = corrélation négative, rouge = positive
pal_cor <- colorRampPalette(rev(brewer.pal(11, "RdBu")))(100)

# Annotation par groupe fonctionnel (bactéries vs plantes)
get_group <- function(taxon) {
  plantes <- c("Betulaceae", "Orchidaceae", "Fabaceae",
               "Solanaceae", "Fagaceae", "Poaceae")
  ifelse(taxon %in% plantes, "Plant", "Bacteria")
}

taxon_groups <- data.frame(
  Groupe = get_group(rownames(cor_taxons)),
  row.names = rownames(cor_taxons)
)

group_colors <- list(
  Groupe = c("Bacteria" = "#2166ac", "Plant" = "#4dac26")
)

# Export PNG
png("heatmap_correlation_taxons.png", width = 1000, height = 900, res = 150)

pheatmap(
  cor_taxons,
  color             = pal_cor,
  clustering_method = "average",
  annotation_row    = taxon_groups,
  annotation_col    = taxon_groups,
  annotation_colors = group_colors,
  main              = "Spearman correlation between taxa",
  fontsize          = 9,
  fontsize_row      = 9,
  fontsize_col      = 9,
  angle_col         = 45,
  border_color      = "grey90",
  breaks            = seq(-1, 1, length.out = 101),
  legend_breaks     = c(-1, -0.5, 0, 0.5, 1),
  legend_labels     = c("-1", "-0.5", "0", "0.5", "1"),
  display_numbers   = TRUE,          # affiche les valeurs dans les cellules
  number_format     = "%.2f",
  number_color      = "black",
  fontsize_number   = 6
)

dev.off()
cat("→ heatmap_correlation_taxons.png exportée\n")

############################################################ pearson
# --- 6. Calcul des corrélations entre taxons ---------------------------------
# On travaille sur la matrice d'abondance originale : sites × taxons
# Corrélation de pearson (robuste aux distributions non-normales)
cor_taxons <- cor(data[,-1], method = "pearson", use = "pairwise.complete.obs")

cat("\nMatrice de corrélation pearson entre taxons (aperçu 4x4) :\n")
print(round(cor_taxons[1:4, 1:4], 3))

# --- 7. Heatmap — Corrélations entre taxons ----------------------------------

# Palette divergente : bleu = corrélation négative, rouge = positive
pal_cor <- colorRampPalette(rev(brewer.pal(11, "RdBu")))(100)

# Annotation par groupe fonctionnel (bactéries vs plantes)
get_group <- function(taxon) {
  plantes <- c("Betulaceae", "Orchidaceae", "Fabaceae",
               "Solanaceae", "Fagaceae", "Poaceae")
  ifelse(taxon %in% plantes, "Plant", "Bactérie")
}

taxon_groups <- data.frame(
  Groupe = get_group(rownames(cor_taxons)),
  row.names = rownames(cor_taxons)
)

group_colors <- list(
  Groupe = c("Bacteria" = "#2166ac", "Plant" = "#4dac26")
)

# Export PNG
png("heatmap_correlation_taxons_pearson.png", width = 1000, height = 900, res = 150)

pheatmap(
  cor_taxons,
  color             = pal_cor,
  clustering_method = "ward.D",
  annotation_row    = taxon_groups,
  annotation_col    = taxon_groups,
  annotation_colors = group_colors,
  main              = "Pearson correlation between taxa",
  fontsize          = 9,
  fontsize_row      = 9,
  fontsize_col      = 9,
  angle_col         = 45,
  border_color      = "grey90",
  breaks            = seq(-1, 1, length.out = 101),
  legend_breaks     = c(-1, -0.5, 0, 0.5, 1),
  legend_labels     = c("-1", "-0.5", "0", "0.5", "1"),
  display_numbers   = TRUE,          # affiche les valeurs dans les cellules
  number_format     = "%.2f",
  number_color      = "black",
  fontsize_number   = 6
)

dev.off()
cat("→ heatmap_correlation_taxons.png exportée\n")

# --- 8. Résumé statistique ---------------------------------------------------
cat("\n===== Résumé =====\n")
cat("Nombre de sites    :", nrow(data), "\n")
cat("Nombre de taxons   :", ncol(data), "\n")
cat("Distance Jaccard min/max :", round(min(dist_jaccard), 3),
    "/", round(max(dist_jaccard), 3), "\n")
cat("Corrélation Spearman min/max :",
    round(min(cor_taxons[lower.tri(cor_taxons)]), 3), "/",
    round(max(cor_taxons[lower.tri(cor_taxons)]), 3), "\n")

cat("\nScript terminé avec succès. Fichiers générés :\n")
cat("  - heatmap_jaccard_sites.png\n")
cat("  - heatmap_correlation_taxons.png\n")
