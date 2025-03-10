#!/bin/bash -v

source /usr/share/modules/init/bash
module use /opt/nvidia/hpc_sdk/modulefiles
module load nvhpc-openmpi3/24.9
source spack-0.23.1/share/spack/setup-env.sh
