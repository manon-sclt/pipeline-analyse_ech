# =============================================================================
# Analysis of blanks (contamination controls)
# =============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)

# =============================================================================
# 1. Loading blank tabular files
# =============================================================================

dossier_blancs <- "C:/Users/coren/Documents/Académique/Master/M1/S8/Ptut/Projet/Blast/Blanc"

fichiers <- list.files(dossier_blancs, pattern = "\\.tabular$", full.names = TRUE)

cols <- c("qseqid", "sseqid", "pident", "length",
          "mismatch", "gapopen", "qstart", "qend",
          "sstart", "send", "evalue", "bitscore", "stitle")

df_blancs <- bind_rows(lapply(fichiers, function(f) {
  df <- read.table(f, sep = "\t", header = FALSE,
                   col.names = cols, fill = TRUE, quote = "")
  df$fichier <- basename(f)
  df
}))
cat("Total sequences in blanks:", nrow(df_blancs), "\n")

# =============================================================================
# 2. Extraction of genus/species from stitle
# =============================================================================

df_blancs <- df_blancs %>%
  mutate(
    espece = sapply(strsplit(as.character(stitle), " "), function(x) {
      if (length(x) >= 2) paste(x[1], x[2]) else x[1]
    }),
    genre = sapply(strsplit(as.character(stitle), " "), function(x) x[1])
  )

# =============================================================================
# 3. Top organisms in blanks
# =============================================================================

top_especes <- df_blancs %>%
  count(espece, sort = TRUE) %>%
  filter(!grepl("genome assembly|chromosome|PREDICTED|complete genome", espece)) %>%
  head(20)

cat("\nTop 20 organisms in blanks:\n")
print(top_especes)

ggplot(top_especes, aes(x = reorder(espece, n), y = n, fill = n)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_gradient(low = "#87CEEB", high = "#E41A1C") +
  labs(
    title = "Top 20 organisms detected in blanks",
    x = NULL,
    y = "Number of sequences",
    fill = "Count"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.y = element_text(face = "italic", size = 9),
    legend.position = "none"
  )

ggsave("~/Académique/Master/M1/S8/Ptut/Projet/MATRICES/blancs_top_organismes.png",
       width = 12, height = 8, dpi = 300)

# =============================================================================
# 4. Comparison by blank sample
# =============================================================================

par_fichier <- df_blancs %>%
  count(fichier, genre, sort = TRUE) %>%
  group_by(fichier) %>%
  top_n(10, n) %>%
  ungroup()

ggplot(par_fichier, aes(x = reorder(genre, n), y = n, fill = fichier)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(
    title = "Organisms detected per blank sample",
    x = NULL,
    y = "Number of sequences",
    fill = "Blank sample"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.y = element_text(face = "italic", size = 9)
  )

ggsave("~/Académique/Master/M1/S8/Ptut/Projet/MATRICES/blancs_par_fichier.png",
       width = 14, height = 8, dpi = 300)

# =============================================================================
# 5. Comparison blanks vs real samples
# =============================================================================

matrice <- read.csv("C:/Users/coren/Documents/Académique/Master/M1/S8/Ptut/Projet/MATRICES/matrice_totale.csv")

taxons_blancs <- df_blancs %>%
  filter(!grepl("genome assembly|chromosome|PREDICTED|complete genome", stitle)) %>%
  mutate(genre = sapply(strsplit(as.character(stitle), " "), function(x) x[1])) %>%
  count(genre, sort = TRUE) %>%
  filter(n >= 5)

cat("\nPotential contaminants (detected >= 5 times in blanks):\n")
print(taxons_blancs)

contaminants <- taxons_blancs$genre
contaminants_dans_matrice <- matrice$Taxon_Cible[matrice$Taxon_Cible %in% contaminants]

cat("\nPotential contaminants present in the matrix:\n")
print(contaminants_dans_matrice)

write.csv(taxons_blancs,
          "C:/Users/coren/Documents/Académique/Master/M1/S8/Ptut/Projet/MATRICES/contaminants_blancs.csv",
          row.names = FALSE)

