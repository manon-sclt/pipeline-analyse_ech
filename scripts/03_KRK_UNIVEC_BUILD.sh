#!/bin/bash
#SBATCH --job-name=kraken_build
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --output=kraken_build_%j.log

# Forcer l'utilisation de FTP/HTTP au lieu de rsync
export KRAKEN2_USE_FTP=1

# Charger conda et kraken2
source /local/env/envconda.sh
conda activate /home/genouest/tp_beg_toulouse_41064/tp60607/kraken2_env

# Variables
THREADS=16
DB_NAME="KRK_univec_human"

# Créer le répertoire de la base
mkdir -p $DB_NAME

echo "=== Étape 1: Téléchargement de la taxonomie NCBI ==="
kraken2-build --download-taxonomy --db $DB_NAME --use-ftp

echo "=== Étape 2: Téléchargement de la librairie UniVec ==="
kraken2-build --download-library UniVec_Core --db $DB_NAME --use-ftp

echo "=== Étape 3: Téléchargement de la librairie Human ==="
kraken2-build --download-library human --db $DB_NAME --use-ftp

echo "=== Étape 4: Construction de la base de données ==="
kraken2-build --build --db $DB_NAME --threads $THREADS

echo "=== Étape 5: Nettoyage des fichiers temporaires ==="
kraken2-build --clean --db $DB_NAME

echo "=== Construction terminée ==="
echo "Base de données disponible dans: $DB_NAME"
echo "Taille finale:"
du -sh $DB_NAME

# Test de la base
echo "=== Test de la base ==="
kraken2 --db $DB_NAME --report test_report.txt --threads 4 \
  <(echo ">test_seq
ATCGATCGATCGATCG")

echo "Base Kraken2 UniVec + Human construite avec succès"