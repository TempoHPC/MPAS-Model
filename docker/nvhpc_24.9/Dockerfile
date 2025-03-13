# docker build -t mpas:8.2.2 .
# docker run --gpus all -it --entrypoint bash mpas:8.2.2
# docker run --gpus all -it --entrypoint bash --rm mpas:8.2.2
# docker exec -i -t <container_name> bash
 
# LNCC
FROM nvcr.io/nvidia/nvhpc:24.9-devel-cuda12.6-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

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

RUN useradd -d /custom/home/monan monan
RUN passwd -d monan
USER monan
WORKDIR /custom/home/monan

RUN wget https://github.com/spack/spack/releases/download/v0.23.1/spack-0.23.1.tar.gz
RUN tar zxvf spack-0.23.1.tar.gz
 
RUN git clone --single-branch --branch branch_v8.2.2 \
    https://github.com/TempoHPC/MPAS-Model.git MPAS-Model_v8.2.2_tempohpc 

