# Scripts pour le projet
Dans cette section nous présenterons les différents scripts qui nous on permit de réaliser la pipeline.  
Toutes les étapes sont réalisées sur le cluster de calcul **GenOuest**.

## 01_TRIMMING_CUTADAPT.sh
Ce script n'a pas encore été ajouté.

## 02_INSTALL_KRAKEN.sh
Ce script nous a permis d'installer l'outil **Kraken2** utilisé pour la classification taxonomique dans notre environnement `kraken2_env` sur GenOuest.

## 03_KRK_RUN.sh
Ce script permet de lancer le run Kraken. Il est a modifié à chaque cycle :  
- `#SBATCH --job-name` pour choisir le nom du job.
- `#SBATCH --mem` plus élevé que 150G pour la base de données GTDB.
- `DB` à modifier en choisissant la banque de donnée souhaitée.
- `OUTPUT_DIR` pour changer le nom du dossier de sortie Kraken.
  
### Ajout de paramètres
Deux nouveaux paramètres ont étés ajoutés pour filtrer les séquences FASTA :  
- `--classified-out` : fichier `.fasta` qui contient les séquences ayant reçu une identification taxonomique dans la base de données sélectionnée.
- `--unclassified-out` : fichier `.fasta` qui contient les séquences dont le taxon n'a pas été identifié dans la base de données. C'est le fichier qu'on va lancer à nouveau des les bases de données suivantes.

## 04_KRK_UNIVEC_BUILD.sh
Ce script nous a permis de créer la base de données "UNIVEC", utile pour identifier l'ADN humain et le trier comme bruit (il ne sera pas utile pour notre étude).
