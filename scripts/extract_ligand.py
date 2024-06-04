import argparse

import pandas as pd
import numpy as np
from rdkit import Chem


def main(args):
    with open(args.filename,"rt") as f:
        lines = f.read().split("\n")
    extract = []
    i = 0
    for j,v in enumerate(lines):
        if v.startswith("HETATM") and v[21] == args.chain:
            i = 1
            extract.append(v)
        elif i == 1 and v.startswith("TER"):
            extract.append("TER")
        elif v.startswith("CONECT"):
            extract.append(v)
    if args.remove_chain:
        pr = []
        for v in lines:
            if v.startswith("HETATM") and v[21] == args.chain:
                break
            pr.append(v)
        with open("protein.pdb","wt") as f:
            f.write("\n".join(pr))

    pdb = "\n".join(extract)
    mol = Chem.MolFromPDBBlock(pdb)
    w = Chem.SDWriter("ligand_chain_{}.sdf".format(args.chain))
    w.write(mol)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("filename",type=str)
    parser.add_argument("--chain",type=str,default="X")
    parser.add_argument("--remove_chain",action="store_true")
    args = parser.parse_args()

    main(args)

