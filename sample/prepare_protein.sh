#!/bin/bash

ROSETTA=/opt/rosetta_3.13/main/source
source /opt/pip-env/bin/activate
SCRIPTS=/workspace/Rosetta/scripts

# 1つのときはfor文不要
# ligandありのときはrelax.xml、金属原子ありのときはrelax_metal.xml
for P in input_protein/*.pdb; do
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s ${P} \
        -parser:protocol ${SCRIPTS}/relax_empty.xml \
        -out:suffix _relaxed \
        -nstruct 1 \
        -out:path:pdb input_protein \
        -out:path:score input_protein \
        -overwrite
    mv ${P%.*}_relaxed_0001.pdb ${P%.*}_relaxed.pdb
done