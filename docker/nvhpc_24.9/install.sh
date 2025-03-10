#!/bin/bash -v

source /usr/share/modules/init/bash
module use /opt/nvidia/hpc_sdk/modulefiles
module load nvhpc-openmpi3/24.9

source spack-0.23.1/share/spack/setup-env.sh
spack compiler find
spack external find m4     
spack external find perl
spack external find cmake
spack external find openmpi
spack external find bzip2

spack install parallelio%nvhpc@=24.9 ^parallel-netcdf ^netcdf-c@4.9.2~blosc~zstd

cd MPAS-Model_v8.2.2_tempohpc 
git pull
make CORE=atmosphere clean && 
source docker/nvhpc_24.9/make.sh

