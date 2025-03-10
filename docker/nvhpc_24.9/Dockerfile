# docker build -t mpas:8.2.0 .
# docker run --gpus all -it --entrypoint bash mpas:8.2.0
# docker run --gpus all -it --entrypoint bash --rm mpas:8.2.0
# docker exec -i -t <container_name> bash
 
# LNCC
FROM nvcr.io/nvidia/nvhpc:24.9-devel-cuda12.6-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

RUN apt update -y && apt upgrade -y
RUN apt install -y build-essential curl git libbsd-dev python3
RUN apt install -y cmake
RUN apt install -y make
RUN apt install -y pkg-config 
RUN apt install -y vim 
RUN apt install -y environment-modules
RUN apt install -y m4
RUN apt install -y perl
RUN apt install -y bzip2 

ENV NUM_PROCS=8
ENV CC=mpicc
ENV FC=mpif90
ENV CPP=$CXX

RUN adduser monan
USER monan
WORKDIR /home/monan


RUN wget https://github.com/spack/spack/releases/download/v0.23.1/spack-0.23.1.tar.gz
RUN tar zxvf spack-0.23.1.tar.gz
 
RUN git clone --single-branch --branch branch_v8.2.2 \
    https://github.com/TempoHPC/MPAS-Model.git MPAS-Model_v8.2.2_tempohpc 

RUN source /usr/share/modules/init/bash && \
module use /opt/nvidia/hpc_sdk/modulefiles && \
module load nvhpc-openmpi3/24.9 && \
source spack-0.23.1/share/spack/setup-env.sh && \
spack compiler find && \
spack external find m4 && \
spack external find perl && \
spack external find cmake && \
spack external find bzip2 && \
spack external find openmpi && \
spack install parallelio%nvhpc@=24.9 ^parallel-netcdf ^netcdf-c@4.9.2~blosc~zstd && \
cd MPAS-Model_v8.2.2_tempohpc && \
git pull && \
make CORE=atmosphere clean && \
source docker/nvhpc_24.9/make.sh

#RUN spack install mpas-model%nvhpc@=24.9 ^parallelio+pnetcdf
#RUN spack install parallel-netcdf%nvhpc@=24.9 



