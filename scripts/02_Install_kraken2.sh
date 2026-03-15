#!/bin/bash
#=========================================================
# Script d'installation de Kraken2 avec Conda
#=========================================================

# 1️⃣ Charger conda, disponible sur le 
source /local/env/envconda.sh

# 2️⃣ Créer un environnement dans le répertoire courant
conda create -y -p $PWD/kraken2_env python=3.10

# 3️⃣ Activer l'environnement
conda activate kraken2_env

# 4️⃣ Installer Kraken2 depuis bioconda
conda install -y -c bioconda kraken2

# 5️⃣ Vérifier l'installation
kraken2 --version

# 6️⃣ vérifier le chemin, c'est le chemin qu'il faudra mettre dans votre script 
which kraken2

echo "Kraken2 a été installé avec succès dans l'environnement 'kraken2_env'."
