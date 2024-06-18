import pandas as pd
import numpy as np
import argparse

import pymol
cmd =  pymol.cmd


def main(args):
    filename = args.filename
    
    pymol.finish_launching(["pymol","-qc"])
    cmd.load(filename)
    cmd.select("sel1","chain X")
    cmd.save("ligand_chain_X.sdf",selection="sel1")
    if args.remove_chain == True:
        cmd.do("remove chain X")
        
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("filename",type=str)
    parser.add_argument("--remove_chain",action="store_true")
    args = parser.parse_args()

    main(args)