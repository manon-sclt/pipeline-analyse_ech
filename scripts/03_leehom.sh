#!/bin/bash
# ─────────────────────────────────────────────
# Étape 3 : Merge des reads avec leeHom
# ─────────────────────────────────────────────

set -euo pipefail

R1="${1:?Usage: $0 <R1> <R2> <sample> <DirMerge> [cpus]}"
R2="${2:?}"
sample="${3:?}"
DirMerge="${4:?}"
CPUS="${5:-${SLURM_CPUS_PER_TASK:-4}}"

mkdir -p "$DirMerge"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lancement de leeHom (${CPUS} CPUs)..."

leeHom \
    --ancientdna \
    -f AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
    -s AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
    -t "$CPUS" \
    -fq1 "$R1" \
    -fq2 "$R2" \
    -fqo "${DirMerge}/${sample}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] leeHom terminé. Sorties dans : ${DirMerge}/${sample}*"
