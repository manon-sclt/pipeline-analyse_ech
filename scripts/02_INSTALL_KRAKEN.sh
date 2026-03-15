#!/bin/bash
#=========================================================
# Script d'installation de Kraken2 avec Conda
#=========================================================

# 1. Charger conda
source /local/env/envconda.sh

# 2. Créer l'environnement et installer Kraken2 en une seule commande
conda create -y -p $PWD/kraken2_env -c bioconda kraken2

# 3. Activer l'environnement (avec le chemin complet)
conda activate $PWD/kraken2_env

# 4. Vérifier l'installation
kraken2 --version

# 5. Afficher le chemin
which kraken2

echo "Kraken2 installé avec succès dans $PWD/kraken2_env"
echo ""
echo "Pour utiliser kraken2 :"
echo "  source /local/env/envconda.sh"
echo "  conda activate $PWD/kraken2_env"
echo "  kraken2 --version"