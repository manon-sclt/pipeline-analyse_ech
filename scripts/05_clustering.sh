#!/bin/bash
# ─────────────────────────────────────────────
# Étape 5 : Clustering avec VSEARCH
#   - Clustering des reads mergés et non-mergés
#   - Production des centroïdes et table de comptage
#   - Seuil d'identité recommandé pour aDNA : 0.95-0.97
# ─────────────────────────────────────────────
# Usage :
#   bash 05_clustering.sh <sample> <DirFinal> <DirClust> [identity]
# ─────────────────────────────────────────────

set -euo pipefail

sample="${1:?Usage: $0 <sample> <DirFinal> <DirClust> [identity]}"
DirFinal="${2:?}"
DirClust="${3:?}"
IDENTITY="${4:-0.96}"

mkdir -p "$DirClust"

# ── Fonction : clustering d'un fichier ──────
run_clustering() {
    local INPUT="$1"
    local LABEL="$2"
    local OUTBASE="${DirClust}/${sample}_${LABEL}"

    if [[ ! -f "$INPUT" ]]; then
        echo "  [SKIP] $LABEL : fichier absent ($INPUT)"
        return
    fi

    local N_IN=$(gzip -dc "$INPUT" | wc -l | awk '{print $1/4}')
    echo "  → $LABEL ($N_IN reads)"

    TMPDIR_LOCAL=$(mktemp -d)
    TMP_IN="${TMPDIR_LOCAL}/input.fastq"
    gzip -dc "$INPUT" > "$TMP_IN"

    vsearch \
        --cluster_size "$TMP_IN" \
        --id "$IDENTITY" \
        --iddef 2 \
        --strand plus \
        --centroids "${OUTBASE}_centroids.fasta" \
        --uc "${OUTBASE}.uc" \
        --sizeout \
        --minseqlength 13 \
        --maxaccepts 1 \
        --maxrejects 8 \
        --qmask none \
        --threads 8 \
        --log "${OUTBASE}_vsearch.log" \
        2>&1 | tee "${OUTBASE}_vsearch_report.txt"

    rm -rf "$TMPDIR_LOCAL"

    local N_CLUSTERS=$(grep -c "^>" "${OUTBASE}_centroids.fasta")
    echo "    ✓ $N_CLUSTERS clusters générés"
    echo "    Centroïdes : ${OUTBASE}_centroids.fasta"
}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Clustering VSEARCH pour : $sample (identité=${IDENTITY})"
echo ""

# ── Traitement des fichiers ──────────────────
# Fichier mergé (depuis FINAL)
run_clustering "${DirFinal}/${sample}_merged_dedup.fq.gz" "merged"

# Fichiers non-mergés (depuis MERGE directement, pas FINAL)
run_clustering "${DirFinal}/../MERGE/${sample}_r1.fq.gz" "r1"
run_clustering "${DirFinal}/../MERGE/${sample}_r2.fq.gz" "r2"

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Clustering terminé pour : $sample"
