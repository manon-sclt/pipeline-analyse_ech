#!/bin/bash

# ==========================================
# 1. NETTOYAGE ET EXTRACTION DYNAMIQUE DES TAXONS
# ==========================================
# On nettoie le dictionnaire ET on extrait en même temps la liste unique 
# de tous les taxons cibles valides pour la passer dynamiquement à AWK.
tr -d '\r' < ./stats_plant/dictionnaire_propre.csv | awk -F',' '$2 != "A_Eliminer" {print $1"\t"$2}' > ./stats_plant/dict_temp.txt

taxons_cibles=$(awk -F'\t' '{print $2}' ./stats_plant/dict_temp.txt | sort -u | tr '\n' ',')

# ==========================================
# 2. EN-TÊTE DU CSV FINAL
# ==========================================
printf "Taxon_Cible" > ./stats_plant/50-390_matrice_abondance_plant.csv

periodes=(
    "Bronze_390" "Bronze_370" "Bronze_350" "Bronze_330"
    "Iron_310" "Iron_290" "Iron_270" "Iron_255" "Iron_240"
    "Roman_190" "Roman_170" "Roman_150" "Roman_130" "Roman_110"
    "Mid_Age_90" "Post_Mid_70" "Post_Mid_50"
)

for p in "${periodes[@]}"; do
    printf ",%s" "$p" >> ./stats_plant/50-390_matrice_abondance_plant.csv
done
echo "" >> ./stats_plant/50-390_matrice_abondance_plant.csv

# ==========================================
# 3. RÉCUPÉRATION DES FICHIERS .TABULAR
# ==========================================

BLAST="./data/FASTA/RESULTS/SORTIE_BLAST"
dossiers=(
    "$BLAST/01_PLASTES"
    "$BLAST/02_PLUSPF"
    "$BLAST/03_PLUSPFP"
    "$BLAST/04_GTDB"
)

fichiers_existants=()
for dossier in "${dossiers[@]}"; do
    for f in "$dossier"/[0-9]*_*.tabular; do
        if [ -f "$f" ]; then
            fichiers_existants+=("$f")
        fi
    done
done

if [ ${#fichiers_existants[@]} -eq 0 ]; then
    echo "ERREUR : Aucun fichier .tabular trouvé dans $dossier"
    exit 1
fi
echo "    ✓ ${#fichiers_existants[@]} fichiers .tabular trouvés"

# ==========================================
# 4. APPEL SÉCURISÉ DU SCRIPT AWK
# ==========================================
# On passe la variable de taxons générée à la volée à l'argument taxons_list
awk -v per_list="${periodes[*]}" \
    -v taxons_list="$taxons_cibles" \
    -f script_matrice.awk ./stats_plant/dict_temp.txt "${fichiers_existants[@]}" >> ./stats_plant/50-390_matrice_abondance_plant.csv

# ==========================================
# 5. NETTOYAGE DES FICHIERS TEMPORAIRES
# ==========================================
rm -f ./stats_plant/dict_temp.txt
echo "Matrice dynamique générée avec succès dans 50-390_matrice_abondance_plant.csv !"