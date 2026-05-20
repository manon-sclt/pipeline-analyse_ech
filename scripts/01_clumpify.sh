#!/bin/bash
# ─────────────────────────────────────────────
# Étape 1 : Déduplication optique avec Clumpify
# ─────────────────────────────────────────────

set -euo pipefail

R1="${1:?Usage: $0 <R1> <R2> <OUT1> <OUT2>}"
R2="${2:?}"
OUT1="${3:?}"
OUT2="${4:?}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lancement de clumpify.sh..."

TMPDIR=$(mktemp -d)
TMP_R1="${TMPDIR}/r1.fastq"
TMP_R2="${TMPDIR}/r2.fastq"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Décompression temporaire des fichiers..."
gzip -dc "$R1" > "$TMP_R1"
gzip -dc "$R2" > "$TMP_R2"

clumpify.sh \
    in1="$TMP_R1" \
    in2="$TMP_R2" \
    out1="$OUT1" \
    out2="$OUT2" \
    optical=t \
    dupedist=40 \
    dedupe=t

rm -rf "$TMPDIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Clumpify terminé."