#!/bin/bash

# =============================================================================
# soupe_pfp.sh
# Script d'extraction, combinaison et filtrage de séquences FASTA par taxon
#
# Pour chaque taxon d'intérêt, ce script :
#   1. Extrait les séquences correspondant au TAXID depuis les fichiers Kraken
#   2. Combine les deux réplicats biologiques (-1 et -2) en un seul fichier
#   3. Filtre les centroïdes selon un seuil de taille de cluster (size)
#
# Dépendances :
#   - extract_kraken_reads.py (KrakenTools)
#   - filter_size.py (script maison)
#   - Python 3 + Biopython
#
# Structure des fichiers attendue :
#   $BASE/krk/     → fichiers Kraken (.krk)
#   $BASE/fasta/   → fichiers FASTA classifiés
#   $BASE/txt/     → rapports Kraken (.txt)
#
# Structure des fichiers produits :
#   $BASE/fasta/results/<taxon>/            → réplicats extraits
#   $BASE/fasta/results/<taxon>/combined/   → réplicats combinés
#   $BASE/fasta/results/<taxon>/filtered/   → séquences filtrées par size
# =============================================================================

# Chemin de base du projet — à modifier selon l'environnement
BASE="/home/Corentin/Documents/Ptut/pfp"

# Seuil minimum de taille de cluster (size)
# Les centroïdes avec size < SIZE_MIN seront exclus (souvent des erreurs de séquençage)
SIZE_MIN=2

# =============================================================================
# Tableau associatif TAXID -> nom du taxon
# Pour ajouter un taxon : TAXONS["TAXID"]="nom"
# Les TAXID sont disponibles sur https://www.ncbi.nlm.nih.gov/taxonomy
# =============================================================================
declare -A TAXONS
TAXONS["15745"]="phragmites"
TAXONS["4479"]="poaceae"
TAXONS["4747"]="orchidaceae"
TAXONS["4070"]="solanaceae"
TAXONS["3803"]="fabaceae"
TAXONS["3503"]="fagaceae"

# Boucle principale sur chaque taxon
for taxid in "${!TAXONS[@]}"; do
    nom="${TAXONS[$taxid]}"

    # Création des dossiers de sortie si inexistants
    mkdir -p "$BASE/fasta/results/${nom}/combined"
    mkdir -p "$BASE/fasta/results/${nom}/filtered"

    echo "======================================"
    echo "=== Taxon : $nom (TAXID: $taxid) ==="
    echo "======================================"

    # Boucle sur chaque strate (profondeur d'échantillonnage, toutes les 20)
    for strate in 690 710 730 750 770 790 810 830 850 870 890 910 930 950 970 990; do
        echo "--- Strate $strate ---"

        # ------------------------------------------------------------------
        # ÉTAPE 1 : Extraction des séquences — réplicat 1
        # -k : fichier rapport Kraken binaire (.krk)
        # -s : fichier FASTA des séquences classifiées
        # -r : fichier rapport Kraken texte (.txt)
        # -o : fichier FASTA de sortie
        # -t : TAXID cible
        # --include-children : inclut toutes les sous-espèces/genres enfants
        # ------------------------------------------------------------------
        python3 extract_kraken_reads.py \
            -k "$BASE/krk/${strate}-1_non_classifies_non_classifies.krk" \
            -s "$BASE/fasta/${strate}-1_non_classifies_non_classifies_classifies.fasta" \
            -r "$BASE/txt/${strate}-1_non_classifies_non_classifies.txt" \
            -o "$BASE/fasta/results/${nom}/${strate}-1_${nom}.fasta" \
            -t $taxid --include-children

        # ÉTAPE 1 : Extraction des séquences — réplicat 2
        python3 extract_kraken_reads.py \
            -k "$BASE/krk/${strate}-2_non_classifies_non_classifies.krk" \
            -s "$BASE/fasta/${strate}-2_non_classifies_non_classifies_classifies.fasta" \
            -r "$BASE/txt/${strate}-2_non_classifies_non_classifies.txt" \
            -o "$BASE/fasta/results/${nom}/${strate}-2_${nom}.fasta" \
            -t $taxid --include-children

        # ------------------------------------------------------------------
        # ÉTAPE 2 : Combinaison des deux réplicats en un seul fichier FASTA
        # ------------------------------------------------------------------
        cat "$BASE/fasta/results/${nom}/${strate}-1_${nom}.fasta" \
            "$BASE/fasta/results/${nom}/${strate}-2_${nom}.fasta" \
            > "$BASE/fasta/results/${nom}/combined/${strate}_${nom}_combined.fasta"

        # ------------------------------------------------------------------
        # ÉTAPE 3 : Filtrage par size (taille du cluster)
        # Seuls les centroïdes avec size >= SIZE_MIN sont conservés
        # Élimine les singletons souvent liés à des erreurs de séquençage
        # ------------------------------------------------------------------
        python3 "$BASE/filter_size.py" \
            -i "$BASE/fasta/results/${nom}/combined/${strate}_${nom}_combined.fasta" \
            -o "$BASE/fasta/results/${nom}/filtered/${strate}_${nom}_filtered.fasta" \
            -s $SIZE_MIN

        echo "  Strate $strate terminée"
    done

    echo "=== $nom terminé ==="
done