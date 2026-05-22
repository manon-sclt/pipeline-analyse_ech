# Scripts used for the project
In this section, we will present the various scripts that enabled us to build the pipeline.  
All steps from 00 to 08 were performed on the **GenOuest** computing cluster. The `Pipeline_01-05.sh` pipeline and `08_KRK_UNIVEC_BUILD.sh` script were created by our supervisor, Ms. Hubler Frédérique and her Master's 2 student.  
The numbers "00" , "01", etc ., were added to the script names to indicate the order in which they should be used.
______________________________________________________________________________________________________________________

## 00_INSTALL_KRAKEN.sh
This script allowed us to install the **Kraken2** tool (Wood et al., 2019), which is used for taxonomic classification, in our `kraken2_env` environment on the GenOuest cluster [https://github.com/DerrickWood/kraken2)](https://github.com/DerrickWood/kraken2).

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
 
A second deduplication pass is applied to the merged reads with `Clumpify` (Bushnell, 2014; dedupe=t, optical=t, dupedist=40, subs=0), to eliminate any residual duplicates resulting from the merging. A complexity filter is then applied with `BBDuk` ([BBTools suite](https://github.com/bbushnell/BBTools/blob/master/bbduk.sh); entropy=0.7, entropywindow=50, entropyk=5), allowing the elimination of low-complexity sequences that could generate false positives during taxonomic assignment.  
 
### Sequence clustering — 05_clustering.sh
 
The merged and filtered reads are grouped into representative units (centroids) using `VSEARCH` (Rognes et al., 2016; available at [VSEARCH](https://github.com/torognes/vsearch)) with the --cluster_size command. An identity threshold of 96% (--id 0.96) is applied, in accordance with recommendations for aDNA. This step reduces redundancy while quantifying the relative abundance of each unique sequence.

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
- Uses of `TaxonKit` (Shen & Ren, 2021)  to download de NCBI Taxonomy local database (if it is not already download), and then converts genus names to TAXID and retrieve the complete taxonomic lineage associated,
- Scans the lineages, classifies organisms of interest and add a `A_Eliminer` tag to what is incorrect,
- Applicates of security filters to reject invalid lines (name without genus/species, typo, etc.),
- Generates a `resume_taxons.csv` files ready to use in Rstudio.
  
**/!\ Note** : This script requires `TaxonKit` available at [https://github.com/shenwei356/taxonkit/releases](https://github.com/shenwei356/taxonkit/releases).

## 11_generer_matrice_dynamique.sh

This script automatises the creation of a taxon abundance matrix (in **CSV** format) that cross-references the identified target plant/bacterial taxon with various historical periods (from the Mesolithic to the Middle Ages in our case). The generated files is formatted for immediate import into ecological statistics or data science packages (such as `vegan` or `ggplot2` in R).  
Here are the main stepts of the script :
- It cleans the plant/bacterial mapping dictionary (`dictionnaire_propre.csv`, an output file of the `10_pipeline_stats_bact.sh` or `10_pipeline_stats_plant.sh` script) to isolate the validated taxa (those not tagged `A_Eliminer`). It then generates a list of these target taxa on the fly, thereby avoiding the need to hard-code the names in the following scripts,
- It writes the header for the final CSV file by creating a column for each chronological-cultural period,
- Thoroughly scans the various BLAST ouput directories (dedicated ton each database selected) for all ecisting .tabular count files,
- Via an `awk` script (`script_matrice.awk`), it will count the occurrences of each plant for each historical period and populate the matrix,
- It deletes all the temporary files to leave only the final result.
  
**/!\ Note** : This script requires the presence of `script_matrice.awk`  located in the project root directory (or to precise its location inside the script).
_____________________________________________________________________
# References

- Bushnell, B. (2014). *BBMap : A Fast, Accurate, Splice-Aware Aligner.* https://escholarship.org/uc/item/1h3515gn  
- Martin, M. (2011). *Cutadapt removes adapter sequences from high-throughput sequencing reads.* **EMBnet.Journal**, 17(1), 10‑12. https://doi.org/10.14806/ej.17.1.200  
- Shen, W., & Ren, H. (2021). *TaxonKit : A practical and efficient NCBI taxonomy toolkit.* **Journal of Genetics and Genomics, Special issue on Microbiome**, 48(9), 844‑850. https://doi.org/10.1016/j.jgg.2021.03.006  
- Renaud, G., Stenzel, U., & Kelso, J. (2014). *leeHom : Adaptor trimming and merging for Illumina sequencing reads.* **Nucleic Acids Research**, 42(18), e141‑e141. https://doi.org/10.1093/nar/gku699  
- Rognes, T., Flouri, T., Nichols, B., Quince, C., & Mahé, F. (2016a). *VSEARCH : A versatile open source tool for metagenomics.* **PeerJ**, 4, e2584. https://doi.org/10.7717/peerj.2584
- Wood, D. E., Lu, J., & Langmead, B. (2019). *Improved metagenomic analysis with Kraken 2.* **Genome Biology**, 20(1), 257. https://doi.org/10.1186/s13059-019-1891-0), 2815‑2839  
  
## Licenses

- `Cutadapt` is under [MIT License](https://github.com/marcelm/cutadapt?tab=MIT-1-ov-file).  
- `BBTools` (`Clumpify` + `BBDuk`) [License](https://github.com/bbushnell/BBTools/tree/master?tab=License-1-ov-file#readme).  
- `KrakenTools` [License](https://github.com/jenniferlu717/KrakenTools?tab=GPL-3.0-1-ov-file#readme).  
- `leeHom` [License](https://github.com/grenaud/leeHom/blob/master/LICENSE).  
- `TaxonKit` is under [MIT License](https://github.com/shenwei356/taxonkit/blob/master/LICENSE).
- `VSEARCH` Licenses : [https://github.com/torognes/vsearch/blob/master/LICENSE.txt](https://github.com/torognes/vsearch/blob/master/LICENSE.txt) ; [https://github.com/torognes/vsearch/blob/master/LICENSE_GNU_GPL3.txt](https://github.com/torognes/vsearch/blob/master/LICENSE_GNU_GPL3.txt).  
