import glob
import argparse
from collections import defaultdict
import re

import pandas as pd 
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import xml.etree.ElementTree as ET

def parse_plip(file):
    tree = ET.parse(file)
    root = tree.getroot()
    d = {}
    for bs in root.findall("bindingsite"):
        props = {}
        iden = bs.find("identifiers")
        name = iden.find("members").find("member").text
        prop = bs.find("lig_properties")
        residue = bs.find("bs_residues")
        for v in prop:
            props[v.tag] = v.text
        resi = {}
        for v in residue.findall("bs_residue"):
            resi[v.attrib["id"]] = v.attrib
        try:
            #chain = bs.find("interacting_chains").find("interacting_chain").text
            interact = bs.find("interactions")
            interaction = defaultdict(list)
            for v in interact:
                for w in v:
                    temp = {}
                    for x in w:
                        if x.text.strip() == "":
                            coord = {}
                            for y in x:
                                coord[y.tag] = y.text
                            temp[x.tag] = coord
                        else:
                            temp[x.tag] = x.text
                    interaction[w.tag].append(temp)
        except AttributeError:
            interaction = {}
        d[name] = {"property":props,"residue":resi,"interaction":interaction}
    return d

def parse_interaction(interaction):
    res = []
    for v, w in interaction.items():
        for x in w:
            d ={}
            d["resnr"] = int(x["resnr"])
            d["restype"] = x["restype"]
            if v == "hydrogen_bond":
                d["dist"] = float(x["dist_d-a"])
            elif v == "pi_stack":
                d["dist"] = float(x["centdist"])
            else:
                d["dist"] = float(x["dist"])
            if v == "metal_complex":
                d["ligcoo"] = x["metalcoo"]
                d["protcoo"] = x["targetcoo"]
            else:
                d["ligcoo"] = x["ligcoo"]
                d["protcoo"] = x["protcoo"]
            d["interaction"] = v
            res.append(d)
    return res

def parse_plip_multi(files,code="LG1:X:1"):
    f = [v.split("/")[-1].split(".")[0] for v in files]
    d = [parse_plip(v) for v in files]
    interacts = [parse_interaction(v[code]["interaction"]) for v in d]
    return {v:w for v,w in zip(f,interacts)}

def IFP(interacts,interaction=True):
    # interacts: dict obtained from parse_plip_multi
    # interaction: bool, whether containing information of type of interaction
    concats = []
    for v,w in interacts.items():
        temp_d = []
        for i,x in enumerate(w):
            temp = {}
            try:
                for y in interacts[str(x)]:
                    if interaction:
                        s = "_".join([v,str(y["resnr"]),y["interaction"]])
                    else:
                        s = "_".join([v,str(y["resnr"])])
                    temp[s] = 1
            except KeyError:
                pass # fill 0 if missing
            temp_d.append(pd.DataFrame(temp,index=[i]))
        temp_d = pd.concat(temp_d)
        temp_d = temp_d.fillna(0)
        concats.append(temp_d)
    concats = pd.concat(concats,axis=1)
    concats = concats[concats.columns.values[concats.sum(axis=0)!=0]]
    return concats
    
