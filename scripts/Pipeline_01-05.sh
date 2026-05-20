#!/bin/bash
# ─────────────────────────────────────────────
# Pipeline principal : clumpify → cutadapt → leeHom → clumpify post-merge → clustering → stats
# Dossiers fixes : RAW / DEDUPE / CUT / MERGE / FINAL / CLUSTER
# ─────────────────────────────────────────────
# Usage :
#   bash pipeline.sh [cpus]
#
# Les dossiers RAW, DEDUPE, CUT, MERGE, FINAL, CLUSTER sont créés
# dans le même répertoire que ce script.
# Format attendu : NOM_R1.fastq.gz / NOM_R2.fastq.gz
# ─────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPUS="${1:-${SLURM_CPUS_PER_TASK:-4}}"

# ── Dossiers fixes ───────────────────────────
DirRaw="${SCRIPT_DIR}/RAW"
DirDedupe="${SCRIPT_DIR}/01_DEDUP"
DirCut="${SCRIPT_DIR}/02_CUTADAPT"
DirMerge="${SCRIPT_DIR}/03_LEEHOM"
DirFinal="${SCRIPT_DIR}/04_CLEAN"
DirClust="${SCRIPT_DIR}/05_CLUSTER"

mkdir -p "$DirDedupe" "$DirCut" "$DirMerge" "$DirFinal" "$DirClust"

# ── Vérification du dossier RAW ──────────────
if [[ ! -d "$DirRaw" ]]; then
    echo "ERREUR : le dossier RAW est introuvable ($DirRaw)"
    exit 1
fi

# ── Détection des paires ─────────────────────
R1_FILES=$(find "$DirRaw" -maxdepth 1 -name "*_R1.fastq.gz" | sort)

if [ -z "$R1_FILES" ]; then
    echo "ERREUR : aucun fichier *_R1.fastq.gz trouvé dans $DirRaw"
    exit 1
fi

NB_PAIRES=$(echo "$R1_FILES" | wc -l | tr -d ' ')

echo "============================================"
echo " Pipeline démarré : $(date '+%Y-%m-%d %H:%M:%S')"
echo " RAW     : $DirRaw"
echo " DEDUPE  : $DirDedupe"
echo " CUT     : $DirCut"
echo " MERGE   : $DirMerge"
echo " FINAL   : $DirFinal"
echo " CLUSTER : $DirClust"
echo " CPUs    : $CPUS"
echo " Paires  : $NB_PAIRES"
echo "============================================"

# ── Boucle sur chaque paire ──────────────────
while IFS= read -r R1; do

    R2="${R1/_R1.fastq.gz/_R2.fastq.gz}"
    sample="$(basename "$R1" _R1.fastq.gz)"

    if [[ ! -f "$R2" ]]; then
        echo "AVERTISSEMENT : R2 introuvable pour '$sample' — paire ignorée."
        continue
    fi

    echo ""
    echo "############################################"
    echo " Échantillon : $sample"
    echo "############################################"

    DEDUPE_R1="${DirDedupe}/${sample}_R1_dedupe.fastq.gz"
    DEDUPE_R2="${DirDedupe}/${sample}_R2_dedupe.fastq.gz"

    echo ">>> [${sample}] ÉTAPE 1/5 — Clumpify"
    bash "${SCRIPT_DIR}/01_clumpify.sh" "$R1" "$R2" "$DEDUPE_R1" "$DEDUPE_R2"

    echo ">>> [${sample}] ÉTAPE 2/5 — Cutadapt"
    bash "${SCRIPT_DIR}/02_cutadapt.sh" "$DEDUPE_R1" "$DEDUPE_R2" "$sample" "$DirCut"

    echo ">>> [${sample}] ÉTAPE 3/5 — leeHom"
    CUT_R1="${DirCut}/${sample}_R1_cutadapt.fastq.gz"
    CUT_R2="${DirCut}/${sample}_R2_cutadapt.fastq.gz"
    bash "${SCRIPT_DIR}/03_leehom.sh" "$CUT_R1" "$CUT_R2" "$sample" "$DirMerge" "$CPUS"

    echo ">>> [${sample}] ÉTAPE 4/5 — Clumpify post-merge (entropie + dédup)"
    bash "${SCRIPT_DIR}/04_clumpify_postmerge.sh" "$sample" "$DirMerge" "$DirFinal"

    echo ">>> [${sample}] ÉTAPE 5/5 — Clustering VSEARCH"
    bash "${SCRIPT_DIR}/05_clustering.sh" "$sample" "$DirFinal" "$DirClust"

    echo "✓ '$sample' traité avec succès."

done <<< "$R1_FILES"
echo ""
echo "============================================"
echo " Pipeline terminé : $(date '+%Y-%m-%d %H:%M:%S')"
