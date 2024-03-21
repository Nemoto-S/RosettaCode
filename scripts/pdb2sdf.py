import os
import sys
from argparse import ArgumentParser
from rdkit import Chem
from rdkit.Chem import AllChem


def pdb2sdf(pdbfile):
    mol = Chem.MolFromPDBFile(pdbfile)
    outfile = pdbfile.split(".")[0] + ".sdf"
    w = Chem.SDWriter(outfile)
    w.write(mol)

if __name__ == "__main__":
    path = sys.argv[1]
    pdb2sdf(path)