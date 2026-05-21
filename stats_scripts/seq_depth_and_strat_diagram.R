#________________________________________________________
#### Chargement des données & librairies ####
#________________________________________________________
setwd("~/Master/cours/M1/S2/PTUT")
library(tidyverse)
library(ggplot2)
library(ggrepel)
library(vegan)
library(rioja)
library(riojaPlot)

## 1. Charger le dictionnaire final
dict_final_bact = read.csv("./stats_bact/dictionnaire_propre.csv")
dict_final_plantes = read.csv("./stats_plant/dictionnaire_propre.csv")
table(dict_final_bact$Taxon_Cible)
table(dict_final_plantes$Taxon_Cible)
#On supprime les "A_Eliminer"
dict_final_bact = dict_final_bact[dict_final_bact$Taxon_Cible != "A_Eliminer",]
dict_final_plantes = dict_final_plantes[dict_final_plantes$Taxon_Cible != "A_Eliminer",]

## 2. Charger les matrices
#Matrices bactéries

matrice_bact = read.csv("./stats_bact/matrice_combinee_bact.csv", row.names = 1, check.names = FALSE) # sans la redondance d'identification
colSums(matrice_bact)
#On retire les 4 premiers caractèresdes dernières périodes pour nettoyer
colnames(matrice_bact) = sub("^X[0-9]{2}_", "", colnames(matrice_bact))
matrice_plantes = read.csv("./stats_plant/matrice_combinee_plant.csv", row.names= 1, check.names = FALSE)

dict_final_bact$Taxon_Cible[dict_final_bact$Taxon_Cible == "" | dict_final_bact$Taxon_Cible == " " | is.na(dict_final_bact$Taxon_Cible)] <- "A_Eliminer" # Place les lignes avec la colonne "Taxon_Cible" vide dans "A_Eliminer"

#________________________________________________________
### --- Statistiques --- ###
#________________________________________________________

# I - Normalisation
# 1. Calculer la profondeur de séquençage par éch + vec odre chrono (Bact)
prof_bact = colSums(matrice_bact)

ordre_chrono = c(
  "Meso_990","Meso_970","Neo_950","Neo_930","Neo_910","Neo_890","Neo_870",
  "Neo_850","Neo_830","Neo_810","Neo_790","Neo_770","Neo_750","Neo_730","Neo_710","Neo_690","Neo_680",
  "Neo_660","Neo_640","Neo_620","Neo_610","Neo_590","Neo_570","Bronze_550","Bronze_530","Bronze_520","Bronze_510",
  "Bronze_490","Bronze_480","Bronze_470","Bronze_450","Bronze_430","Bronze_410", "Bronze_390", "Bronze_370", "Bronze_350",
  "Bronze_330","Iron_310", "Iron_290", "Iron_270", "Iron_255", "Iron_240",
  "Roman_190", "Roman_170", "Roman_150", "Roman_130", "Roman_110",
  "Mid_Age_90", "Post_Mid_70", "Post_Mid_50"
)

# 2. Convertir en df + vecteur chrono en facteur
df_prof_bact = data.frame(
  Echantillon = names(prof_bact),
  Reads = prof_bact
)
df_prof_bact$Echantillon = factor(df_prof_bact$Echantillon, levels = ordre_chrono)

#Visulisation
ggplot(df_prof_bact, aes(x=Echantillon, y=Reads)) +
  geom_bar(stat="identity", fill="skyblue", width=0.8) +
  theme_minimal() +
  labs(
    title = "Sequencing depth distribution (Bacteria)",
    x = "Samples in chronological order",
    y = "Total number of reads"
  ) +
  theme(
    plot.title = element_text(hjust=0.5, face ="bold"),
   axis.text.x = element_text(angle=45, vjust=0.5, hjust=1, size=8),
   axis.title.x = element_text(margin = margin(t = 15))
  )

ggsave("~/Master/cours/M1/S2/PTUT/Analyse_stat/figures/prof_bact.png",
       width = 14, height = 7, dpi = 300)

# 1.b Calculer la profondeur de séquençage par éch + vec odre chrono (Plantes)
prof_plant = colSums(matrice_plantes)

ordre_chrono = c(
  "Meso_990","Meso_970","Neo_950","Neo_930","Neo_910","Neo_890","Neo_870",
  "Neo_850","Neo_830","Neo_810","Neo_790","Neo_770","Neo_750","Neo_730","Neo_710","Neo_690","Neo_680",
  "Neo_660","Neo_640","Neo_620","Neo_610","Neo_590","Neo_570","Bronze_550","Bronze_530","Bronze_520","Bronze_510",
  "Bronze_490","Bronze_480","Bronze_470","Bronze_450","Bronze_430","Bronze_410", "Bronze_390", "Bronze_370", "Bronze_350",
  "Bronze_330","Iron_310", "Iron_290", "Iron_270", "Iron_255", "Iron_240",
  "Roman_190", "Roman_170", "Roman_150", "Roman_130", "Roman_110",
  "Mid_Age_90", "Post_Mid_70", "Post_Mid_50"
)

# 2. Convertir en df + vecteur chrono en facteur
df_prof_plant = data.frame(
  Echantillon = names(prof_plant),
  Reads = prof_plant
)
df_prof_plant$Echantillon = factor(df_prof_plant$Echantillon, levels = ordre_chrono)

#Visulisation de la profondeur de séquençage
ggplot(df_prof_plant, aes(x=Echantillon, y=Reads)) +
  geom_bar(stat="identity", fill="skyblue", width=0.8) +
  theme_minimal() +
  labs(
    title = "Sequencing depth distribution (Plants)",
    x = "Samples in chronological order",
    y = "Total number of reads",
  ) +
  theme(
    plot.title = element_text(hjust=0.5, face ="bold"),
    axis.text.x = element_text(angle=45, vjust=0.5, hjust=1, size=8),
    axis.title.x = element_text(margin = margin(t = 15))
  )

### --- Diagramme de stratigraphie --- ###
# 1. On inverse les période (du plus ancien vers le bas au plus récent vers le haut)
ordre_inverse = rev(ordre_chrono)
profondeurs_num = as.numeric(gsub(".*_", "", ordre_inverse))

### - Bactéries - ###
# 2. Transposition de la matrice bact
matrice_transp_bact = as.data.frame(t(matrice_bact))
matrice_ordonnee = matrice_transp_bact[ordre_inverse, ] # Pour avoir les lignes dans le bon ordre

# 3. Convertir les nombre de reads en ab relative
matrice_pourcent = as.matrix(matrice_ordonnee / rowSums(matrice_ordonnee) * 100)

# 4. On sélectionne les taxons avec au moins 1% d'abondance
seuil_abondance = apply(matrice_pourcent, 2, max)
taxons_selectionnes = matrice_pourcent[, seuil_abondance >= 1]
#Transf de Helliger pour les taxons ultra-dominants
matrice_hellinger = sqrt(taxons_selectionnes / 100) * 100

# 5. On transforme la matrice en tableau long
df_paleo = as.data.frame(taxons_selectionnes) %>%
  mutate(Profondeur = profondeurs_num) %>%
  pivot_longer(cols = -Profondeur, names_to = "Taxon", values_to = "Abondance")

### - Plantes - ###
# 1. L'ordre inverse et les profondeurs sont déjà créés (on garde les mêmes)
# ordre_inverse = rev(ordre_chrono)
# profondeurs_num = as.numeric(gsub(".*_", "", ordre_inverse))

# 2. Transposition de la matrice plantes
matrice_transp_plantes = as.data.frame(t(matrice_plantes))
matrice_ordonnee_plantes = matrice_transp_plantes[ordre_inverse, ] 

# 3. Convertir les nombres de reads des plantes en abondance relative (%)
matrice_pourcent_plantes = as.matrix(matrice_ordonnee_plantes / rowSums(matrice_ordonnee_plantes) * 100)

# 4. Sélection des taxons de plantes avec au moins 1% d'abondance
seuil_abondance_plantes = apply(matrice_pourcent_plantes, 2, max)
plantes_selectionnees = matrice_pourcent_plantes[, seuil_abondance_plantes >= 1]


### --- Diagramme de stratification --- ###
# 1. Préparation de l'axe de profondeur
df_profondeurs <- data.frame(Profondeur = profondeurs_num)

# Convertir les matrices en data.frame
df_plantes <- as.data.frame(plantes_selectionnees)
df_bacteries <- as.data.frame(taxons_selectionnes)

#Redimensionner le graph
png("./Analyse_stat/figures/diagram_strat.png", width = 2000, height = 1200, res = 150)
# Ajouter des marges
par(mar = c(4, 5, 10, 2))
# =========================================================
# 2. PROXY 1 : LES PLANTES
# =========================================================
rp1 = riojaPlot(
  x = df_plantes, 
  y = df_profondeurs, 
  
  # Configuration de l'axe Y
  ymin = 0, 
  ymax = 1000, 
  yinterval = 100, 
  
  ylabel = "Depth (cm)", 
  
  # Graphique
  scale.percent = TRUE,
  plot.line = TRUE, 
  plot.poly = TRUE,
  col.poly = "darkolivegreen4", 
  plot.bar = FALSE,
  
  # Rotation et tailles
  srt.xlabel = 60, 
  tcl = -0.1, 
  cex.yaxis = 0.9,
  cex.ylabel = 1,
  cex.xlabel = 1, 
  cex.xaxis = 0.9,
  
  xRight = 0.45
)

# =========================================================
# 3. PROXY 2 : LES BACTÉRIES
# =========================================================
riojaPlot(
  x = df_bacteries, 
  y = df_profondeurs[, "Profondeur", drop = FALSE], 
  
  riojaPlot = rp1,
  xGap = 0.02,
  xRight = 0.99, 
  
  # Graphique
  scale.percent = TRUE,
  plot.line = TRUE, 
  plot.poly = TRUE,
  col.poly = "cadetblue4", 
  plot.bar = FALSE,
  
  srt.xlabel = 60,
  cex.xlabel = 1,
  cex.xaxis = 0.9,
  
  do.clust = TRUE,        # rajoute la classification  CONISS
  plot.clust = TRUE,      # Dessine le dendrogramme
  plot.zones = "auto",    # Trace les lignes rouges qui délimitent les zones de rupture significative
)


