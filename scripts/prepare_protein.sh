#!/bin/bash

ROSETTA=/opt/rosetta_3.13/main/source
source /opt/pip-env/bin/activate
SCRIPTS=/workspace/Rosetta/scripts

OPT=`getopt -o l:p:e -l ligand:,protein:,empty_relax -- "$@"`
if [ $? != 0 ] ; then
    exit 1
fi
eval set -- "$OPT"
E_ARG=false

while true
do 
    case $1 in
        -l | --ligand) 
            L_ARG=$2
            shift 2
            ;;
        -p | --protein)
            P_ARG=$2
            shift 2
            ;;
        -e | --empty_relax)
            E_ARG=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Internal error!" 1>&2
            exit 1
            ;;
    esac
done

if $E_ARG; then
    mpirun -np 10 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s ${P_ARG%.*}.pdb \
        -parser:protocol ${SCRIPTS}/relax_empty.xml \
        -out:suffix _relax \
        -nstruct 1 \
        -out:path:pdb input_protein \
        -out:path:score input_protein \
        -overwrite
    mv ${P_ARG%.*}_relax.pdb ${P_ARG%.*}_relaxed.pdb

else
    python3 ${ROSETTA}/scripts/python/public/molfile_to_params.py ${L_ARG} \
        -p ${L_ARG%.*} \
        --mm-as-virt \
        --chain X \
        --clobber
    center=$(python3 ${SCRIPTS}/center.py ${L_ARG%.*}_0001.pdb)
    center=(${center//,/ })
    cat ${P_ARG} ${L_ARG%.*}_0001.pdb > ${P_ARG%.*}_relax.pdb

    mpirun -np 10 --allow-run-as-root ${ROSETTA}/bin/rosetta_scripts.mpi.linuxgccrelease \
        -s ${P_ARG%.*}_relax.pdb \
        -in:file:extra_res_fa ${L_ARG%.*}.params \
        -parser:protocol ${SCRIPTS}/relax.xml \
        -out:suffix _relax \
        -nstruct 1 \
        -out:path:pdb input_protein \
        -out:path:score input_protein \
        -overwrite \
        -parser:script_vars x=${center[0]} y=${center[1]} z=${center[2]}
    python3 ${SCRIPTS}/extract_ligand.py ${P_ARG%.*}_relax_relax_0001.pdb --remove_chain
    mv protein.pdb ${P_ARG%.*}_relaxed_withligand.pdb
    rm ${P_ARG%.*}_relax_relax_0001.pdb
fi


