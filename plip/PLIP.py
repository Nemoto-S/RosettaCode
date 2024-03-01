import argparse

import plip
from plip.structure.preparation import PDBComplex
from plip.basic import config
from plip.exchange.report import StructureReport
from plip import plipcmd
from rdkit import Chem


def main(args,visualize=False):
    mol = PDBComplex()
    mol.load_pdb(args.file)
    mol.analyze()
    streport = StructureReport(mol,outputprefix=args.outprefix)
    streport.outpath = args.outpath
    streport.write_xml()
    if visualize == True:
        from plip.basic.remote import VisualizerData
        from plip.visualization.visualize import visualize_in_pymol
        complexes = [VisualizerData(mol,site) for site in sorted(mol.interaction_sets) if not len(mol.interaction_sets[site].interacting_res) == 0]
        [visualize_in_pymol(plcomp) for plcomp in complexes]

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file",type=str,default=None)
    parser.add_argument("--outpath",type=str,default="results")
    parser.add_argument("--outprefix",type=str,default="out")
    args = parser.parse_args()
    main(args)