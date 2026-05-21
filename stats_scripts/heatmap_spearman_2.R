# ============================================================
# Heatmap des p-valeurs de corrélation de Spearman
# Correction des tests multiples : Benjamini-Hochberg (FDR)
# Cellules rouges = p ajustée < 0.05
# ============================================================

# ── 1. Packages ─────────────────────────────────────────────
if (!requireNamespace("ggplot2",   quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("reshape2",  quietly = TRUE)) install.packages("reshape2")

library(ggplot2)
library(reshape2)

# ── 2. Chargement des données ────────────────────────────────
# La première colonne est l'identifiant échantillon (row names)
setwd("/home/karrouchi/Documents/PTUT_analyse_figure")
df <- read.csv("matrice_totale.csv", row.names = 1, check.names = FALSE)

taxons <- colnames(df)
n      <- length(taxons)

# ── 3. Calcul des corrélations de Spearman + p-valeurs ──────
rho_mat  <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))
pval_mat <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))

for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    if (i != j) {
      test            <- cor.test(df[[i]], df[[j]], method = "spearman", exact = FALSE)
      rho_mat[i, j]  <- test$estimate
      pval_mat[i, j] <- test$p.value
    }
  }
}

# ── 4. Correction de Benjamini-Hochberg (FDR) ───────────────
# On extrait tous les tests off-diagonaux, on corrige, puis on remet en matrice
off_idx       <- which(!is.na(pval_mat))          # indices linéaires hors diagonale
adj_pvals     <- p.adjust(pval_mat[off_idx], method = "BH")

adj_pval_mat  <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))
adj_pval_mat[off_idx] <- adj_pvals

cat("Nombre de paires significatives (p ajustée < 0.05) :",
    sum(adj_pval_mat < 0.05, na.rm = TRUE), "\n")

# ── 5. Mise en forme longue pour ggplot2 ────────────────────
adj_df <- melt(adj_pval_mat, varnames = c("Taxon_X", "Taxon_Y"),
               value.name = "p_adj")

# Supprimer la diagonale (NA)
adj_df <- adj_df[!is.na(adj_df$p_adj), ]

# Variable de couleur : "sig" ou "non_sig"
adj_df$significatif <- ifelse(adj_df$p_adj < 0.05, "sig", "non_sig")

# Label affiché dans chaque cellule
adj_df$label <- ifelse(adj_df$p_adj < 0.001,
                       formatC(adj_df$p_adj, format = "e", digits = 1),
                       round(adj_df$p_adj, 3))

# Ordonner les taxons (ordre du fichier original)
adj_df$Taxon_X <- factor(adj_df$Taxon_X, levels = taxons)
adj_df$Taxon_Y <- factor(adj_df$Taxon_Y, levels = taxons)

# Créer une colonne facteur discrète pour le remplissage des tuiles
adj_df$categorie <- cut(
  adj_df$p_adj,
  breaks         = c(-Inf, 0.01, 0.05, Inf),
  labels         = c("p adj. [0.00 – 0.01]", "p adj. (0.01 – 0.05]", "p adj. ≥ 0.05 (NS)"),
  include.lowest = TRUE
)

# ── 6. Tracé de la heatmap ──────────────────────────────────
p <- ggplot(adj_df, aes(x = Taxon_Y, y = Taxon_X, fill = categorie)) +

  # Tuiles colorées selon la catégorie discrète
  geom_tile(color = "white", linewidth = 0.3) +

  # Couleurs manuelles sur variable discrète (pas de problème de type)
  scale_fill_manual(
    values = c(
      "p adj. [0.00 – 0.01]" = "#b30000",
      "p adj. (0.01 – 0.05]" = "#e04040",
      "p adj. ≥ 0.05 (NS)"   = "#cccccc"
    ),
    name = "p-valeur ajustée (BH)"
  ) +

  # Annotations textuelles
  geom_text(aes(label = label,
                color  = significatif),
            size = 2.5) +
  scale_color_manual(values = c("sig" = "white", "non_sig" = "#555555"),
                     guide  = "none") +

  # Axes et thème
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y      = element_text(size = 9),
    axis.title       = element_blank(),
    panel.grid       = element_blank(),
    legend.position  = "bottom",
    legend.title     = element_text(face = "bold"),
    plot.title       = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle    = element_text(size = 9,  hjust = 0.5, color = "grey40"),
    plot.margin      = margin(10, 10, 10, 10)
  ) +

  labs(
    title    = "Heatmap des p-valeurs de corrélation de Spearman",
    subtitle = "Correction des tests multiples par la méthode de Benjamini-Hochberg (FDR)\nCellules rouges : p ajustée < 0.05"
  ) +

  # Conserver les proportions carrées
  coord_fixed()

# ── 7. Export ────────────────────────────────────────────────
ggsave("spearman_heatmap_BH.png", plot = p,
       width = 14, height = 12, dpi = 180, bg = "white")

cat("Figure sauvegardée : spearman_heatmap_BH.png\n")
