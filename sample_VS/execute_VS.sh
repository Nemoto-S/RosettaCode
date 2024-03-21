#!/bin/bash

ROSETTA=/opt/rosetta_3.13/main/source  # Rosetta source path
source /opt/pip-env/bin/activate  # activate python environment
SCRIPTS=/workspace/RosettaCode/scripts  # RosettaCode/scripts path

mkdir output
mkdir output2
mkdir output3
mkdir output_dock
mkdir output2_dock
mkdir output3_dock

# ligand preparation
bash ConformerGenerator.sh

# protein preparation
bash ${SCRIPTS}/prepare_protein.sh -p input_protein/2yfe_protein.pdb -e

# 1st docking
python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py \
    input_ligand/2yfe_ligand.sdf \
    -p input_ligand/2yfe_ligand \
    --mm-as-virt \
    --chain X \
    --clobber
center=$(python3 ${SCRIPTS}/center.py input_ligand/2yfe_ligand.pdb)
center=(${center//,/ })

for P in input_ligand/*.sdf; do
    python3 ${SCRIPTS}/sdf_split.py $P -n 1
    for P2 in ${P%.*}_*.sdf; do
        PA=${P2%.*}
        python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ${P2} \
            -p ligand_chain_X \
            --mm-as-virt \
            --chain X \
            --clobber
        
        cat input_protein/2yfe_protein_relaxed.pdb ligand_chain_X_0001.pdb > dock.pdb
        mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
            -s dock.pdb \
            -extra_res_fa ligand_chain_X.params \
            -out:file:scorefile output/${PA##*/}.sc \
            -out:pdb true \
            -out:prefix output_dock/${PA##*/}_ \
            -packing:ex1 \
            -packing:ex2 \
            -packing:no_optH \
            -packing:flip_HNQ \
            -parser:protocol dock.xml \
            -overwrite \
            -mistakes:restore_pre_talaris_2013_behavior true \
            -nstruct 50 \
            -score:analytic_etable_evaluation true \
            -parser:script_vars x=${center[0]} y=${center[1]} z=${center[2]}
        rm ligand_chain_X.*
        rm $P2
    done
    rm ${P}_*.sdf
done

# score parse and selection
bash ${SCRIPTS}/sc_parser.sh output
python3 ${SCRIPTS}/select_score.py \
    --score_path "output" \
    --criteria "interface" \
    --number 10


# 2nd docking
for P in output_dock/*.pdb; do
    PA=${P%.*}
    python3 ${SCRIPTS}/extract_ligand.py $P --remove_chain
    python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ligand_chain_X.sdf \
        -p ligand_chain_X \
        --mm-as-virt \
        --chain X \
        --clobber
    cat protein.pdb ligand_chain_X_0001.pdb > dock.pdb
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s dock.pdb \
        -extra_res_fa ligand_chain_X.params \
        -out:file:scorefile output2/${LA##*/}.sc \
        -out:pdb true \
        -out:prefix output2_dock/${LA##*/}_ \
        -packing:ex1 \
        -packing:ex2 \
        -packing:no_optH \
        -packing:flip_HNQ \
        -parser:protocol dock2.xml \
        -overwrite \
        -mistakes:restore_pre_talaris_2013_behavior true \
        -nstruct 50 \
        -score:analytic_etable_evaluation true 
done

bash ${SCRIPTS}/sc_parser.sh output2
python3 ${SCRIPTS}/select_score.py \
    --score_path "output2" \
    --criteria "interface" \
    --number 10

# 3rd docking
for P in output2_dock/*.pdb; do
    PA=${P%.*}
    python3 ${SCRIPTS}/extract_ligand.py $P --remove_chain
    python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ligand_chain_X.sdf \
        -p ligand_chain_X \
        --mm-as-virt \
        --chain X \
        --clobber
    cat protein.pdb ligand_chain_X_0001.pdb > dock.pdb
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s dock.pdb \
        -extra_res_fa ligand_chain_X.params \
        -out:file:scorefile output3/${LA##*/}.sc \
        -out:pdb true \
        -out:prefix output3_dock/${LA##*/}_ \
        -packing:ex1 \
        -packing:ex2 \
        -packing:no_optH \
        -packing:flip_HNQ \
        -parser:protocol dock3.xml \
        -overwrite \
        -mistakes:restore_pre_talaris_2013_behavior true \
        -nstruct 50 \
        -score:analytic_etable_evaluation true 
done

bash ${SCRIPTS}/sc_parser.sh output3