#!/bin/bash
# ─────────────────────────────────────────────
# Étape 2 : Trimming des adaptateurs avec Cutadapt
# ─────────────────────────────────────────────

set -euo pipefail

R1="${1:?Usage: $0 <R1> <R2> <sample> <DirCut>}"
R2="${2:?}"
sample="${3:?}"
DirCut="${4:?}"

mkdir -p "$DirCut"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lancement de cutadapt..."

cutadapt \
    -j 6 \
    -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
    -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
    -O 4 \
    -e 0.4 \
    -m 13 \
    -q 15 \
    --trim-n \
    -o "${DirCut}/${sample}_R1_cutadapt.fastq.gz" \
    -p "${DirCut}/${sample}_R2_cutadapt.fastq.gz" \
    "$R1" "$R2" \
    > "${DirCut}/${sample}_cutadapt_report.txt" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cutadapt terminé. Rapport : ${DirCut}/${sample}_cutadapt_report.txt"
