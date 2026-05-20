#!/bin/bash
# ─────────────────────────────────────────────
# Étape 4 : Post-merge dédup + filtre entropie
#   Traitement uniquement du fichier mergé (NOM.fq.gz)
#   1. Clumpify : déduplication
#   2. BBDuk    : filtre de complexité (entropie)
# ─────────────────────────────────────────────
# Usage :
#   bash 04_clumpify_postmerge.sh <sample> <DirMerge> <DirFinal>
# ─────────────────────────────────────────────

set -euo pipefail

sample="${1:?Usage: $0 <sample> <DirMerge> <DirFinal>}"
DirMerge="${2:?}"
DirFinal="${3:?}"

mkdir -p "$DirFinal"

ENTROPY=0.7
INPUT="${DirMerge}/${sample}.fq.gz"
OUTPUT="${DirFinal}/${sample}_merged_dedup.fq.gz"

if [[ ! -f "$INPUT" ]]; then
    echo "ERREUR : fichier mergé introuvable ($INPUT)"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dédup + filtre entropie pour : ${sample}.fq.gz"

TMPDIR_LOCAL=$(mktemp -d)
TMP_IN="${TMPDIR_LOCAL}/input.fastq"
TMP_DEDUP="${TMPDIR_LOCAL}/dedup.fastq.gz"

gzip -dc "$INPUT" > "$TMP_IN"

# Étape 1 : déduplication
clumpify.sh \
    in="$TMP_IN" \
    out="$TMP_DEDUP" \
    dedupe=t \
    optical=t \
    dupedist=40 \
    subs=0 \
    qin=33 \
    groups=1

# Étape 2 : filtre d'entropie
bbduk.sh \
    in="$TMP_DEDUP" \
    out="$OUTPUT" \
    entropy="$ENTROPY" \
    entropywindow=50 \
    entropyk=5 \
    qin=33

rm -rf "$TMPDIR_LOCAL"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Terminé : $(gzip -dc "$OUTPUT" | wc -l | awk '{print $1/4}') reads conservés"
