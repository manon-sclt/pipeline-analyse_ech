#!/bin/bash

# =============================================================================
# pipeline_stats_plant.sh
# Pipeline complet de préparation des données pour les stats
# De la collecte des BLAST jusqu'au dictionnaire propre et au résumé par taxon
#
# Usage : bash pipeline_stats_plant.sh
# =============================================================================

set -euo pipefail

BASE="/home/manon/PTUT"
BLAST="$BASE/data/FASTA/RESULTS/SORTIE_BLAST"
WORKDIR="$BASE/stats_plant"
TAXONKIT="$BASE/taxonkit"

mkdir -p "$WORKDIR"

echo "============================================"
echo " Pipeline stats démarré : $(date '+%Y-%m-%d %H:%M:%S')"
echo " BLAST    : $BLAST"
echo " WORKDIR  : $WORKDIR"
echo "============================================"

# =============================================================================
# ÉTAPE 1 : Collecter toutes les espèces de tous les fichiers tabular
# =============================================================================
echo ""
echo ">>> ÉTAPE 1 : Collecte de toutes les espèces..."

find "$BLAST/01_PLASTES" "$BLAST/02_PLUSPF" "$BLAST/03_PLUSPFP" "$BLAST/04_GTDB" -name "*.tabular" \
    | xargs cat 2>/dev/null \
    | awk -F'\t' '{print $13}' \
    | sort \
    | uniq \
    > "$WORKDIR/toutes_les_especes_projet.txt"

NB=$(wc -l < "$WORKDIR/toutes_les_especes_projet.txt")
echo "    ✓ $NB espèces uniques collectées → toutes_les_especes_projet.txt"

# =============================================================================
# ÉTAPE 2 : Nettoyage des noms d'espèces
# =============================================================================
echo ""
echo ">>> ÉTAPE 2 : Nettoyage des noms d'espèces..."

cat << 'EOF' > "$WORKDIR/nettoyer_liste.awk"
{
    # 1. Nettoyage des préfixes de bases de données
    if ($1 == "MAG:" || $1 == "TPA:") {
        $1 = ""; $0 = $0;
    }

    # 2. Nettoyage des statuts
    if ($1 == "PREDICTED:" || tolower($1) == "uncultured" || tolower($1) == "mutant") {
        $1 = ""; $0 = $0;
    }

    # 3. Sécurité double uncultured
    if (tolower($1) == "uncultured") {
        $1 = ""; $0 = $0;
    }

    # 4. Suppression des virgules dans les mots (evite les stitle type "Genre espece, complete genome")
    gsub(/,/, "", $1)
    gsub(/,/, "", $2)
    gsub(/,/, "", $3)

    # 5. Gestion des hybrides "Genre x espece"
    if ($2 == "x" || $2 == "X") {
        print $1 " " $3;
    } else {
        print $1 " " $2;
    }
}
EOF

awk -f "$WORKDIR/nettoyer_liste.awk" "$WORKDIR/toutes_les_especes_projet.txt" \
    | sort | uniq \
    > "$WORKDIR/dictionnaire_global.csv"

rm "$WORKDIR/nettoyer_liste.awk"

NB=$(wc -l < "$WORKDIR/dictionnaire_global.csv")
echo "    ✓ $NB entrées dans le dictionnaire global → dictionnaire_global.csv"

# =============================================================================
# ÉTAPE 3 : Extraction des genres uniques
# =============================================================================
echo ""
echo ">>> ÉTAPE 3 : Extraction des genres uniques..."

awk '{print $1}' "$WORKDIR/dictionnaire_global.csv" \
    | sort | uniq \
    | grep -v "^$" \
    > "$WORKDIR/liste_genres_uniques.txt"

NB=$(wc -l < "$WORKDIR/liste_genres_uniques.txt")
echo "    ✓ $NB genres uniques → liste_genres_uniques.txt"

# =============================================================================
# ÉTAPE 4 : Installation et configuration de TaxonKit
# =============================================================================
echo ""
echo ">>> ÉTAPE 4 : Vérification de TaxonKit..."

if [[ ! -f "$TAXONKIT" ]]; then
    echo "    TaxonKit non trouvé, téléchargement..."
    wget -q https://github.com/shenwei356/taxonkit/releases/latest/download/taxonkit_linux_amd64.tar.gz \
        -O "$BASE/taxonkit.tar.gz"
    tar -zxvf "$BASE/taxonkit.tar.gz" -C "$BASE"
    chmod +x "$TAXONKIT"
    rm "$BASE/taxonkit.tar.gz"
    echo "    ✓ TaxonKit installé"
else
    echo "    ✓ TaxonKit déjà présent"
fi

TAXDB="$HOME/.taxonkit"
if [[ ! -f "$TAXDB/names.dmp" ]]; then
    echo "    Base de données NCBI Taxonomy non trouvée, téléchargement..."
    mkdir -p "$TAXDB"
    wget -q https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz \
        -O "$TAXDB/taxdump.tar.gz"
    tar -zxvf "$TAXDB/taxdump.tar.gz" -C "$TAXDB"
    rm "$TAXDB/taxdump.tar.gz"
    echo "    ✓ Base de données NCBI Taxonomy installée"
else
    echo "    ✓ Base de données NCBI Taxonomy déjà présente"
fi

# =============================================================================
# ÉTAPE 5 : Récupération des lignées avec TaxonKit
# =============================================================================
echo ""
echo ">>> ÉTAPE 5 : Récupération des lignées taxonomiques..."

"$TAXONKIT" name2taxid "$WORKDIR/liste_genres_uniques.txt" \
    | "$TAXONKIT" lineage -i 2 \
    > "$WORKDIR/lignees_genres.txt"

NB=$(wc -l < "$WORKDIR/lignees_genres.txt")
echo "    ✓ $NB lignées récupérées → lignees_genres.txt"

# =============================================================================
# ÉTAPE 6 : Attribution des taxons cibles
# =============================================================================
echo ""
echo ">>> ÉTAPE 6 : Attribution des taxons cibles..."

awk -F'\t' '
NR==FNR {
    genre = tolower($1)
    lineage = tolower($3)

    # ── Rhizosphère ──────────────────────────
    if      (lineage ~ /(^|;)orchidaceae(;|$)/)  group[genre] = "Orchidaceae"
    else if (lineage ~ /(^|;)solanaceae(;|$)/)   group[genre] = "Solanaceae"
    else if (lineage ~ /(^|;)fabaceae(;|$)/)     group[genre] = "Fabaceae"
    else if (lineage ~ /(^|;)fagaceae(;|$)/)     group[genre] = "Fagaceae"
    else if (lineage ~ /(^|;)poaceae(;|$)/)      group[genre] = "Poaceae"
    else if (lineage ~ /(^|;)betulaceae(;|$)/)   group[genre] = "Betulaceae"
    else                                          group[genre] = "A_Eliminer"
    next
}
FNR==1 { print "Nom_BLAST,Taxon_Cible"; next }
{
    split(tolower($1), mots, " ")
    premier_mot = mots[1]
    if (premier_mot in group)
        taxon = group[premier_mot]
    else
        taxon = "A_Eliminer"
    print $1 "," taxon
}' "$WORKDIR/lignees_genres.txt" "$WORKDIR/dictionnaire_global.csv" \
    > "$WORKDIR/dictionnaire_final_ncbi.csv"

NB=$(grep -v "A_Eliminer" "$WORKDIR/dictionnaire_final_ncbi.csv" | wc -l)
echo "    ✓ Dictionnaire final créé → dictionnaire_final_ncbi.csv"
echo "    ✓ $NB entrées attribuées à un taxon cible"

# =============================================================================
# ÉTAPE 7 : Nettoyage final des noms
# =============================================================================
echo ""
echo ">>> ÉTAPE 7 : Nettoyage final des noms..."

awk -F',' '
BEGIN { OFS="," }
{
    gsub(/[^a-zA-Z0-9 .]/, "", $1)
    gsub(/  +/, " ", $1)
    print $0
}' "$WORKDIR/dictionnaire_final_ncbi.csv" \
    > "$WORKDIR/dictionnaire_propre.csv"

echo "    ✓ Dictionnaire propre → dictionnaire_propre.csv"

# =============================================================================
# ÉTAPE 7bis : Filtrage des entrées invalides
# =============================================================================
echo ""
echo ">>> ÉTAPE 7bis : Filtrage des entrées invalides..."

awk -F',' '
BEGIN { OFS="," }
NR==1 { print; next }
{
    split($1, mots, " ")
    premier_mot = mots[1]

    # Éliminer les noms vides ou espaces
    if ($1 ~ /^[[:space:]]*$/) next
    # Éliminer si premier mot pas de la forme Genre (Majuscule + minuscules)
    if (premier_mot !~ /^[A-Z][a-z]{2,}$/) next
    # Éliminer si contient un point (R.capsulatus)
    if ($1 ~ /\./) next
    # Éliminer si contient des mots-clés de gènes ou génomes
    if ($1 ~ /complete|plasmid|plastid|chromosome|genome|sequence|gene|ntr[A-Z]|fragment/) next
    # Éliminer si pas de second mot (pas de genre + espèce)
    if ($1 !~ / /) next

    print $0
}' "$WORKDIR/dictionnaire_propre.csv" \
    > "$WORKDIR/dictionnaire_filtre.csv"

NB=$(wc -l < "$WORKDIR/dictionnaire_filtre.csv")
echo "    ✓ $NB entrées valides → dictionnaire_filtre.csv"

# =============================================================================
# ÉTAPE 8 : Résumé des comptes par taxon cible
# =============================================================================
echo ""
echo ">>> ÉTAPE 8 : Comptage par taxon cible..."

awk -F',' '
NR==1 { next }
$1 == "" { next }
{ count[$2]++ }
END {
    printf "\n%-25s %s\n", "Taxon", "Nombre de séquences"
    printf "%-25s %s\n", "─────────────────────────", "───────────────────"
    for (taxon in count)
        printf "%-25s %d\n", taxon, count[taxon]
}' "$WORKDIR/dictionnaire_filtre.csv" | sort -k2 -rn

# Version CSV pour RStudio
awk -F',' '
NR==1 { next }
$1 == "" { next }
{ count[$2]++ }
END {
    print "Taxon,Nombre"
    for (taxon in count)
        print taxon "," count[taxon]
}' "$WORKDIR/dictionnaire_filtre.csv" \
    | sort -t',' -k2 -rn \
    > "$WORKDIR/resume_taxons.csv"

echo ""
echo "    ✓ Résumé → resume_taxons.csv"

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================
echo ""
echo "============================================"
echo " Pipeline terminé : $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo " Fichiers produits dans $WORKDIR :"
echo "   - toutes_les_especes_projet.txt"
echo "   - dictionnaire_global.csv"
echo "   - liste_genres_uniques.txt"
echo "   - lignees_genres.txt"
echo "   - dictionnaire_final_ncbi.csv"
echo "   - dictionnaire_propre.csv"
echo "   - dictionnaire_filtre.csv"
echo "   - resume_taxons.csv"
echo "============================================"