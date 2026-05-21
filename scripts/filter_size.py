#!/usr/bin/env python3

import os
import re
import argparse
from Bio import SeqIO

def parse_args():
    parser = argparse.ArgumentParser(description="Filtre les centroïdes par size minimum")
    parser.add_argument("-i", "--input", required=True, help="Fichier FASTA d'entrée")
    parser.add_argument("-o", "--output", required=True, help="Fichier FASTA de sortie")
    parser.add_argument("-s", "--size", type=int, default=2, help="Size minimum (défaut: 2)")
    return parser.parse_args()

def main():
    args = parse_args()
    
    total = 0
    garde = 0
    
    with open(args.output, 'w') as out:
        for record in SeqIO.parse(args.input, "fasta"):
            total += 1
            match = re.search(r'size=(\d+)', record.description)
            if match:
                size = int(match.group(1))
                if size >= args.size:
                    SeqIO.write(record, out, "fasta")
                    garde += 1
    
    print(f"Total : {total} centroïdes")
    print(f"Gardés (size >= {args.size}) : {garde}")
    print(f"Filtrés : {total - garde}")

if __name__ == "__main__":
    main()
