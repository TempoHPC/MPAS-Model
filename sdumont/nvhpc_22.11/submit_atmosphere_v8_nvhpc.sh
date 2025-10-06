#!/bin/bash
#SBATCH --nodes=1                #Número de Nós
#SBATCH --ntasks=8               #Numero total de tarefas MPI
#SBATCH -p sequana_gpu_dev                  #Fila (partition) a ser utilizada
#SBATCH -J init_atmosphere       #Nome job
#SBATCH --time=00:20:00          #Obrigatório
#SBATCH --ntasks-per-node=8    #Número de tarefas por Nó
#SBATCH --gpus=1

#export LD_LIBRARY_PATH=/scratch/cenapadrjsd/monan/usr/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/scratch/cenapadrjsd/rpsouto/usr/lib64:$LD_LIBRARY_PATH

module load git/2.23_sequana
module load python/3.9.1_sequana
module load gcc/9.3_sequana
module use /scratch/cenapadrjsd/rpsouto/opt/nvidia/hpc_sdk/modulefiles
module load nvhpc/22.11
export NVLOCALRC=/scratch/cenapadrjsd/rpsouto/opt/nvidia/hpc_sdk/Linux_x86_64/localrc

workdir=/scratch/cenapadrjsd/rpsouto
version=v0.18.1
spackdir=${workdir}/spack/sequana/${version}
. ${spackdir}/share/spack/setup-env.sh
export SPACK_USER_CONFIG_PATH=${workdir}/spack/sequana/.spack/${version}

#echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

#echo "spack env activate monan"
spack env activate monan

#echo "spack load parallelio --only dependencies"
#spack load parallelio --only dependencies

#echo "spack load --list"
spack load --list

export NETCDF=$(spack location -i netcdf-fortran)
export PNETCDF=$(spack location -i parallel-netcdf)
echo "NETCDF : $NETCDF"
echo "PNETCDF: $PNETCDF"

export LD_LIBRARY_PATH=$NETCDF/lib:$PNETCDF/lib:$LD_LIBRARY_PATH

echo $LD_LIBRARY_PATH

#ldd ./atmosphere_model_nvhpc

cd  $SLURM_SUBMIT_DIR
mpirun -n $SLURM_NTASKS \
	--mca mpi_cuda_support 0 \
./atmosphere_model_nvhpc
