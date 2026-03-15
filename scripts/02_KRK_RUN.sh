#!/bin/bash
#SBATCH --job-name=kraken2_loop
#SBATCH --output=kraken2_%j.out
#SBATCH --error=kraken2_%j.err
#SBATCH --time=7-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=150G

##################################
# ENVIRONNEMENT CONDA
##################################

source /local/env/envconda.sh
conda activate /home/genouest/tp_beg_toulouse_41064/tp60607/kraken2_env

##################################
# PARAMÈTRES
##################################

DB="KRK_univec_human"  # ajouter la banque que vous voulez, par exemple /db/kraken2/current/k2_pluspf_20251015

INPUT_DIR="DATA"
OUTPUT_DIR="01_OUTPUT_univec_human"

CONF=0.1 # 10 % des k-mers sont suffisantes pour assigner un taxon
THREADS=16

##################################
# VÉRIFICATIONS
##################################

if [ ! -d "$DB" ]; then
	echo "Erreur : base Kraken2 introuvable : $DB"
	exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
	echo "Erreur : dossier d'entrée introuvable : $INPUT_DIR"
	exit 1
fi

# Création du dossier de sortie s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

##################################
# BOUCLE KRAKEN2
##################################

echo "Début des analyses Kraken2"
echo "Base : $DB"
echo "Input : $INPUT_DIR"
echo "Output : $OUTPUT_DIR"
echo "Confidence : $CONF"
echo "Threads : $THREADS"
echo "----------------------------------"

for FASTA in "$INPUT_DIR"/*.fasta; do
	
	# Vérifie qu'au moins un fichier existe
	[ -e "$FASTA" ] || { echo "Aucun fichier .fasta trouvé"; exit 1; }
	
	BASENAME=$(basename "$FASTA" .fasta)
	OUT_PREFIX="${OUTPUT_DIR}/${BASENAME}"
	
	echo "Traitement : $BASENAME"
	
	kraken2 \
	--db "$DB" \
	--memory-mapping \
	--confidence "$CONF" \
	--threads "$THREADS" \
	--report "${OUT_PREFIX}.txt" \
	--output "${OUT_PREFIX}.krk" \
	--unclassified-out "${OUT_PREFIX}_non_classifies.fasta" \
	--classified-out "${OUT_PREFIX}_non_classifies.fasta" \
	--use-names \
	"$FASTA"
	
	echo "Terminé : $BASENAME"
	echo "----------------------------------"
	
done

echo "Toutes les analyses Kraken2 sont terminées"