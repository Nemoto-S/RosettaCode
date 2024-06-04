#!/bin/bash

ROSETTA=/opt/rosetta_3.13/main/source
source /opt/pip-env/bin/activate
SCRIPTS=/workspace/Rosetta/scripts

for P in input_protein/*_processed.pdb; do
    mpirun -np 50 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s ${P} \
        -parser:protocol ${SCRIPTS}/relax_empty.xml \
        -out:suffix _relaxed \
        -nstruct 1 \
        -out:path:pdb input_protein \
        -out:path:score input_protein \
        -overwrite
    mv ${P%.*}_relaxed_0001.pdb ${P%_*}_relaxed.pdb
done