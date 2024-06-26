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

# 1st docking
python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py \
    input_ligand/2yfe_ligand.sdf \
    -p input_ligand/2yfe_ligand \
    --mm-as-virt \
    --chain X \
    --clobber
center=$(python3 ${SCRIPTS}/center.py input_ligand/2yfe_ligand_0001.pdb)
center=(${center//,/ })

for P in input_ligand/*_conf.sdf; do
    python3 ${SCRIPTS}/sdf_split.py $P -n 1
    for P2 in ${P%.*}_*.sdf; do
        PA=${P2%.*}
        PB=${P%_conf*}
        python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ${P2} \
            -p ligand_chain_X \
            --mm-as-virt \
            --chain X \
            --clobber
        
        cat input_protein/2yfe_relaxed.pdb ligand_chain_X_0001.pdb > dock.pdb
        mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
            -s dock.pdb \
            -extra_res_fa ligand_chain_X.params \
            -out:file:scorefile output/${PB##*/}.sc \
            -out:pdb true \
            -out:prefix output_dock/${PA##*/}_ \
            -packing:ex1 \
            -packing:ex2 \
            -packing:no_optH false \
            -packing:flip_HNQ true \
            -parser:protocol dock.xml \
            -overwrite \
            -mistakes:restore_pre_talaris_2013_behavior true \
            -nstruct 50 \
            -score:analytic_etable_evaluation true \
            -parser:script_vars x=${center[0]} y=${center[1]} z=${center[2]}
        rm $P2
    done
done

# score parse and selection
for SC in output/*.sc; do
    python3 ${SCRIPTS}/sc_parser.py "${SC}"
    rm ${SC}
done
python3 ${SCRIPTS}/select_score.py \
    --score_path "output" \
    --criteria "interface" \
    --number 100


# 2nd docking
for P in output_dock/*.pdb; do
    PA=${P%.*}
    PB=${PA##*/}
    PC=${PB%_conf_*}
    python3 ${SCRIPTS}/extract_ligand_pymol.py $P 
    python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ligand_chain_X.sdf \
        -p ligand_chain_X \
        --mm-as-virt \
        --chain X \
        --clobber
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s $P \
        -extra_res_fa ligand_chain_X.params \
        -out:file:scorefile output2/${PC}.sc \
        -out:pdb true \
        -out:prefix output2_dock/ \
        -packing:ex1 \
        -packing:ex2 \
        -packing:no_optH false \
        -packing:flip_HNQ true \
        -parser:protocol dock2.xml \
        -overwrite \
        -mistakes:restore_pre_talaris_2013_behavior true \
        -nstruct 50 \
        -score:analytic_etable_evaluation true 
done
for SC in output2/*.sc; do
    python3 ${SCRIPTS}/sc_parser.py "${SC}"
    rm ${SC}
done
python3 ${SCRIPTS}/select_score.py \
    --score_path "output2" \
    --criteria "interface" \
    --number 100

# 3rd docking
for P in output2_dock/*.pdb; do
    PA=${P%.*}
    PB=${PA##*/}
    PC=${PB%_conf_*}
    python3 ${SCRIPTS}/extract_ligand_pymol.py $P 
    python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ligand_chain_X.sdf \
        -p ligand_chain_X \
        --mm-as-virt \
        --chain X \
        --clobber
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s $P \
        -extra_res_fa ligand_chain_X.params \
        -out:file:scorefile output3/${PC}.sc \
        -out:pdb true \
        -out:prefix output3_dock/ \
        -packing:ex1 \
        -packing:ex2 \
        -packing:no_optH false \
        -packing:flip_HNQ true \
        -parser:protocol dock3.xml \
        -overwrite \
        -mistakes:restore_pre_talaris_2013_behavior true \
        -nstruct 50 \
        -score:analytic_etable_evaluation true 
done

for SC in output3/*.sc; do
    python3 ${SCRIPTS}/sc_parser.py "${SC}"
    rm ${SC}
done