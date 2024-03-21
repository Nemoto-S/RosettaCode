#!/bin/bash

source /opt/pip-env/bin/activate
SCRIPTS=/workspace/RosettaCode/scripts

for FILE in output_dock/*.pdb; do
    INDEX=${FILE%.*}
    INDEX=${INDEX#*/}
    python3 ${SCRIPTS}/PLIP.py ${FILE} --outpath "plip_result" --outprefix ${INDEX}