#!/bin/bash

ntasks=${1}
nthreads=${2}

source /usr/share/modules/init/bash
module use /opt/nvidia/hpc_sdk/modulefiles
module load nvhpc-openmpi3/24.9

workdir=/home/monan/spack-0.23.1
spackdir=${workdir}
source ${spackdir}/share/spack/setup-env.sh

export SPACK_USER_CONFIG_PATH=${workdir}/.spack/${version}

export NETCDF=$(spack location -i netcdf-fortran)
export PNETCDF=$(spack location -i parallel-netcdf)

echo "NETCDF: ${NETCDF}"
echo "PNETCDF: ${PNETCDF}"

export LD_LIBRARY_PATH=$NETCDF/lib:$PNETCDF/lib:$LD_LIBRARY_PATH

echo $LD_LIBRARY_PATH

export OMP_NUM_THREADS=${nthreads}

mpirun -n ${ntasks} \
        --mca mpi_cuda_support 0 \
        ./atmosphere_model 2>&1 | tee run_mpas.out



        
