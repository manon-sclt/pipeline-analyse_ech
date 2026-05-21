# =================================================
# Heatmaps : Distance de Bray Curtis entre sites 
# =================================================

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


# ⬇️ AJOUT : définir les noms de lignes à partir de la colonne Echantillon
rownames(data) <- data$Echantillon
data <- data[, -1]   # supprimer la colonne Echantillon maintenant qu'elle est en rownames

# --- 3. Calcul de la distance de bray entre sites -------------------------
dist_bray <- vegdist(data, method = "bray")   # data est déjà sans la col. Echantillon
mat_bray  <- as.matrix(dist_bray)

# --- 5. Heatmap — Distance de bray entre sites ----------------------------

# Palette de couleurs (0 = identiques → bleu, 1 = totalement différents → rouge)
pal_bray <- colorRampPalette(brewer.pal(9, "YlOrRd"))(100)

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
  Période = get_period(rownames(mat_bray)),
  row.names = rownames(mat_bray)
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
png("heatmap_bray_sites_single.png", width = 1400, height = 1200, res = 150)

pheatmap(
  mat_bray,
  color             = pal_bray,
  clustering_method = "single",
  annotation_row    = periods,
  annotation_col    = periods,
  annotation_colors = period_colors,
  main              = "Bray-Curtis distance between each samples (comparative abundance of taxa)",
  fontsize          = 8,
  fontsize_row      = 7,
  fontsize_col      = 7,
  angle_col         = 45,
  border_color      = NA,
  legend_breaks     = seq(0, 1, by = 0.2),
  legend_labels     = seq(0, 1, by = 0.2)
)

dev.off()
cat("→ heatmap_bray_sites.png exportée\n")



