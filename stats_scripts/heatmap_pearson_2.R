# ============================================================
# Heatmap 1 : Corrélations de Pearson (rho)
# Heatmap 2 : P-valeurs ajustées (Benjamini-Hochberg)
# ============================================================

# ── 1. Packages ─────────────────────────────────────────────
for (pkg in c("ggplot2", "reshape2", "gridExtra")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
library(ggplot2)
library(reshape2)
library(gridExtra)

# ── 2. Chargement et normalisation des données ───────────────
setwd("/home/karrouchi/Documents/PTUT_analyse_figure")
df <- read.csv("matrice_totale.csv", row.names = 1, check.names = FALSE)

# Normalisation (z-score) — scale() retourne une matrice, on repasse en data.frame
df_s <- as.data.frame(scale(df))

taxons <- colnames(df_s)
n      <- length(taxons)

# ── 3. Calcul des corrélations de Pearson + p-valeurs ───────
rho_mat  <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))
pval_mat <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))

for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    if (i != j) {
      # Extraction correcte des colonnes par position
      xi <- df_s[, i]
      xj <- df_s[, j]

      # Filtrer les paires avec au moins 3 valeurs finies communes
      ok <- is.finite(xi) & is.finite(xj)
      if (sum(ok) >= 3) {
        test           <- cor.test(xi[ok], xj[ok], method = "pearson", exact = FALSE)
        rho_mat[i, j]  <- test$estimate
        pval_mat[i, j] <- test$p.value
      }
    }
  }
}

# ── 4. Correction Benjamini-Hochberg (FDR) ───────────────────
off_idx   <- which(!is.na(pval_mat))
adj_pvals <- p.adjust(pval_mat[off_idx], method = "BH")

adj_pval_mat <- matrix(NA, nrow = n, ncol = n, dimnames = list(taxons, taxons))
adj_pval_mat[off_idx] <- adj_pvals

cat("Paires significatives (p ajustée < 0.05) :",
    sum(adj_pval_mat < 0.05, na.rm = TRUE), "\n")

# ── 5. Heatmap 1 : Corrélations (rho) ────────────────────────
rho_df <- melt(rho_mat, varnames = c("Taxon_X", "Taxon_Y"), value.name = "rho")
rho_df <- rho_df[!is.na(rho_df$rho), ]
rho_df$label <- round(rho_df$rho, 2)
rho_df$Taxon_X <- factor(rho_df$Taxon_X, levels = taxons)
rho_df$Taxon_Y <- factor(rho_df$Taxon_Y, levels = taxons)

p_rho <- ggplot(rho_df, aes(x = Taxon_Y, y = Taxon_X, fill = rho)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_gradient2(
    low      = "#2166ac",
    mid      = "white",
    high     = "#b2182b",
    midpoint = 0,
    limits   = c(-1, 1),
    name     = "Correlation\n(Pearson ρ)"
  ) +
  geom_text(aes(label = label), size = 2.5, color = "black") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x     = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y     = element_text(size = 9),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "right",
    legend.title    = element_text(face = "bold"),
    plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.margin     = margin(10, 10, 10, 10)
  ) +
  labs(title = "Correlation matrix of Pearson between each taxa (normalized data") +
  coord_fixed()

# ── 6. Heatmap 2 : P-valeurs ajustées ────────────────────────
adj_df <- melt(adj_pval_mat, varnames = c("Taxon_X", "Taxon_Y"), value.name = "p_adj")
adj_df <- adj_df[!is.na(adj_df$p_adj), ]

adj_df$significatif <- ifelse(adj_df$p_adj < 0.05, "sig", "non_sig")
adj_df$label <- ifelse(
  adj_df$p_adj < 0.001,
  formatC(adj_df$p_adj, format = "e", digits = 1),
  as.character(round(adj_df$p_adj, 3))
)
adj_df$categorie <- cut(
  adj_df$p_adj,
  breaks         = c(-Inf, 0.01, 0.05, Inf),
  labels         = c("p adj. ≤ 0.01", "p adj. (0.01 – 0.05]", "p adj. ≥ 0.05 (NS)"),
  include.lowest = TRUE
)
adj_df$Taxon_X <- factor(adj_df$Taxon_X, levels = taxons)
adj_df$Taxon_Y <- factor(adj_df$Taxon_Y, levels = taxons)

p_pval <- ggplot(adj_df, aes(x = Taxon_Y, y = Taxon_X, fill = categorie)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_manual(
    values = c(
      "p adj. ≤ 0.01"         = "#b30000",
      "p adj. (0.01 – 0.05]"  = "#e04040",
      "p adj. ≥ 0.05 (NS)"    = "#cccccc"
    ),
    name = "ajusted p.value (BH)"
  ) +
  geom_text(aes(label = label, color = significatif), size = 2.5) +
  scale_color_manual(values = c("sig" = "white", "non_sig" = "#555555"), guide = "none") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x     = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y     = element_text(size = 9),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "bottom",
    legend.title    = element_text(face = "bold"),
    plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle   = element_text(size = 9, hjust = 0.5, color = "grey40"),
    plot.margin     = margin(10, 10, 10, 10)
  ) +
  labs(
    title    = "P.value of Pearson correlation test between each Taxa (Normalized data)",
    subtitle = "Multiple test correction : Benjamini-Hochberg (FDR)\nCellules red : p ajusted < 0.05"
  ) +
  coord_fixed()

# ── 7. Export ─────────────────────────────────────────────────
ggsave("pearson_heatmap_rho.png",  plot = p_rho,  width = 14, height = 12, dpi = 180, bg = "white")
ggsave("pearson_heatmap_pval.png", plot = p_pval, width = 14, height = 12, dpi = 180, bg = "white")

cat("Figures sauvegardées :\n  - pearson_heatmap_rho.png\n  - pearson_heatmap_pval.png\n")
