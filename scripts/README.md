# Scripts used for the project
In this section, we will present the various scripts that enabled us to build the pipeline.  
All steps from 00 to 08 were performed on the **GenOuest** computing cluster. The `Pipeline_01-05.sh` pipeline and `08_KRK_UNIVEC_BUILD.sh` script were created by our supervisor, Ms. Hubler Frédérique and her Master's 2 student.  
The numbers "00" , "01", etc ., were added to the script names to indicate the order in which they should be used.
______________________________________________________________________________________________________________________

## 00_INSTALL_KRAKEN.sh
This script allowed us to install the **Kraken2** tool, which is used for taxonomic classification, in our `kraken2_env` environment on the GenOuest cluster [Kraken2](https://github.com/DerrickWood/kraken2).

## Pipeline_01-05.sh
**Note**: *This pipeline was entirely developed and executed by a Master's student at the University of Rennes as part of the ARMeRIE project. The cleaned FASTA files produced by this pipeline constitute the input data of our analyses.*  
  
The data preprocessing was carried out in five successive automated steps within a bash pipeline executed on the GENOUEST computing cluster (documentation available at: [doc Genouest](https://help.genouest.org/usage/cluster/)). The steps are described below in their order of execution.  
  
### Optical deduplication — 01_clumpify.sh
 
The first step consists of removing optical and PCR duplicates using `Clumpify` (Bushnell, 2014; available at: [clumpify](https://sourceforge.net/projects/bbmap/)). Read pairs in compressed FASTQ format are processed with the following parameters: optical=t, dupedist=40 and dedupe=t. The dupedist=40 parameter corresponds to the maximum distance in pixels between two clusters on the Illumina flowcell beyond which two identical reads are not considered optical duplicates. This step reduces noise from sequencing artefacts.  
 
### Adapter trimming — 02_cutadapt.sh
 
Illumina adapter trimming is performed with `Cutadapt` (Martin, 2011; available at: [cutadapt](https://github.com/marcelm/cutadapt/)). The forward adapter (**AGATCGGAAGAGCACACGTCTGAACTCCAGTCA**) and reverse adapter (**AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT**) are removed with the following parameters: -O=4 (minimum overlap length), -e=0.4 (maximum error rate), -m=13 (minimum length of retained reads), -q=15 (minimum 3' quality score) and --trim-n (removal of N bases at extremities). These parameters were optimised for ancient DNA, characterised by short fragments and damage at sequence ends.
 
### Paired-read merging — 03_leehom.sh
 
The merging of R1 and R2 reads is performed with `leeHom` (Renaud et al., 2014; available at: [leeHom](https://github.com/grenaud/leeHom)), a tool specifically designed for ancient DNA (aDNA) processing. leeHom was selected because it outperforms generalist merging tools in the aDNA context, notably through its Bayesian probabilistic model that accounts for damage profiles of degraded DNA. The `--ancientdna` option is activated to adapt the merging parameters to aDNA characteristics. The same adapter sequences as for Cutadapt are provided.
 
### Post-processing of merged reads — 04_clumpify_postmerge.sh
 
A second deduplication pass is applied to the merged reads with `Clumpify` (Bushnell, 2014; dedupe=t, optical=t, dupedist=40, subs=0), to eliminate any residual duplicates resulting from the merging. A complexity filter is then applied with `BBDuk` (BBTools suite; entropy=0.7, entropywindow=50, entropyk=5), allowing the elimination of low-complexity sequences that could generate false positives during taxonomic assignment.  
 
### Sequence clustering — 05_clustering.sh
 
The merged and filtered reads are grouped into representative units (centroids) using `VSEARCH` (Rognes et al., 2016) with the --cluster_size command. An identity threshold of 96% (--id 0.96) is applied, in accordance with recommendations for aDNA. This step reduces redundancy while quantifying the relative abundance of each unique sequence.

## 08_KRK_UNKVEC_BUILD.sh

This script was used by our supervisor to create the UNIVEC_human that allowed her to identified human DNA (contaminants) into our samples and to exclude it from our bioinformatics analyses.
____________________________________________________________________________________________
After this first part of the pipline, we had to run BLASTn on [Galaxy](https://usegalaxy.eu/) which allowed us to compare our unknown sequences to a reference database (NT NCBI 20 Aug. 2024). Galaxy generated `.tabular` output files that will serve as input files for the next step of our pipeline.  
  
## 09_extraction.sh 

This homemade script allowed us to :
 - Extract unique sequences associated to a specific TAXID with `extract_kraken_reads.py` (a special script from `KrakenTools`), including the subspecies (`--include-children`),
 - Combine the biological replicats of the same strate (1 et 2),  
 - Eliminate singletons often linked to sequencing errors by running the `filter_size.py` Python script.
  
**/!\ Note** : This script requires `Python3` with `Biopython` library ([https://biopython.org/](https://biopython.org/)), the `KrakenTools` library ([https://github.com/jenniferlu717/KrakenTools](https://github.com/jenniferlu717/KrakenTools)), and to place the local script `filter_size.py` located in the project root directory (or to modify the path in the variable `BASE="path/to/your/project"` inside the script).  

## 10_pipeline_stats_bact.sh & 10_pipeline_stats_plant.sh

This script automatises the entire post-processing workflow for BLAST output (`.tabular` files). Its primary purpose is to clean up raw species assignements, query the official NCBI taxonomy, and organize a "clean" dataset ready for statistical analysis (particularly in Rstudio).  
Here are the main steps of the script :
- Via an `awk` script, it removes common noise and frequent annotation artifacts from the databases (prefixes such as "**MAG :**" or "**TPA :**", statuses such as "**PREDICTED :**" or "**unclutured**", and extraneous textual content). It then isolates the list of unique genus,
- Uses of `TaxonKit` to download de NCBI Taxonomy local database (if it is not already download), and then converts genus names to TAXID and retrieve the complete taxonomic lineage associated,
- Scans the lineages, classifies organisms of interest and add a `A_Eliminer` tag to what is incorrect,
- Applicates of security filters to reject invalid lines (name without genus/species, typo, etc.),
- Generates a `resume_taxons.csv` files ready to use in Rstudio.
  
**/!\ Note** : This script requires `TaxonKit` available at [https://github.com/shenwei356/taxonkit/releases](https://github.com/shenwei356/taxonkit/releases).

## 11_generer_matrice_dynamique.sh

This script automatise the creation of a taxon abundance matrix (in **CSV** format) that cross-references the identified target plant/bacterial taxon with various historical periods (from the Mesolithic to the Middle Ages in our case). The generated files is formatted for immediate import into ecological statistics or data science packages (such as `vegan` or `ggplot2` in R).  
Here are the main stepts of the script :
- It cleans the plant/bacterial mapping dictionary (`dictionnaire_propre.csv`, an output file of the `10_pipeline_stats_bact.sh` or `10_pipeline_stats_plant.sh` script) to isolate the validated taxa (those not tagged `A_Eliminer`). It then generates a list of these target taxa on the fly, thereby avoiding the need to hard-code the names in the following scripts,
- It writes the header for the final CSV file by creating a column for each chronological-cultural period,
- Thoroughly scans the various BLAST ouput directories (dedicated ton each database selected) for all ecisting .tabular count files,
- Via an `awk` script (`script_matrice.awk`), it will count the occurrences of each plant for each historical period and populate the matrix,
- It deletes all the temporary files to leave only the final result.
  
**/!\ Note** : This script requires the presence of `script_matrice.awk`  located in the project root directory (or to precise its location inside the script).
