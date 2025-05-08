# docker build --no-cache -t mpas:8.2.2 .
# docker run --gpus all -it --entrypoint bash mpas:8.2.2
# docker run --gpus all -it --entrypoint bash --rm mpas:8.2.2
# docker exec -i -t <container_name> bash

FROM nvcr.io/nvidia/nvhpc:24.9-devel-cuda12.6-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]


#Variáveis de diretórios principais

ENV MPAS_DIR=/home/monan/MPAS-Model_v8.2.2_tempohpc \
    BENCHMARK_DIR=/home/monan/MPAS-A_benchmark_120km_v7.0

#Instalar dependências do sistema
RUN apt update -y && apt upgrade -y && apt install -y \
    build-essential \
    curl \
    git \
    libbsd-dev \
    python3 \
    cmake \
    make \
    pkg-config \
    vim \
    environment-modules \
    m4 \
    perl \
    bzip2 \
    wget

#Criar usuário e home

RUN adduser --disabled-password --gecos "" monan
USER monan
WORKDIR /home/monan

#Baixar Spack

RUN wget https://github.com/spack/spack/releases/download/v0.23.1/spack-0.23.1.tar.gz && \
    tar zxvf spack-0.23.1.tar.gz

#Clonar MPAS
RUN git clone --single-branch --branch branch_v8.2.2 https://github.com/TempoHPC/MPAS-Model.git ${MPAS_DIR}


#Instalar Spack e compilar MPAS
RUN echo $USER && \
    echo $HOME && \
    cd && \
    source /usr/share/modules/init/bash && \
    module use /opt/nvidia/hpc_sdk/modulefiles && \
    module load nvhpc-openmpi3/24.9 && \
    source /home/monan/spack-0.23.1/share/spack/setup-env.sh && \
    spack compiler find && \
    spack external find m4 perl cmake openmpi bzip2 && \
    spack install parallelio%nvhpc@=24.9 ^parallel-netcdf ^netcdf-c@4.9.2~blosc~zstd && \
    export NETCDF=$(spack location -i netcdf-fortran) && \
    export PNETCDF=$(spack location -i parallel-netcdf) && \
    ln -sf $(spack location -i netcdf-c)/lib/libnetcdf* ${NETCDF}/lib/ && \
    cd ${MPAS_DIR} && \
    git pull && \
    make CORE=atmosphere clean && \
    make -j ${NUM_PROCS} pgi CORE=atmosphere USE_PIO=false OPENACC=true OPENMP=true PRECISION=single 2>&1 | tee make.output

#Baixar benchmark e extrair
RUN wget https://www2.mmm.ucar.edu/projects/mpas/benchmark/v7.0/MPAS-A_benchmark_120km_v7.0.tar.gz && \
    tar -xvzf MPAS-A_benchmark_120km_v7.0.tar.gz


#Remover arquivos 
RUN find ${BENCHMARK_DIR} -maxdepth 1 \( -name "*.TBL" -o -name "*.DBL" -o -name "RRTMG*" \) -exec rm -f {} \;


#Linkar arquivos 
RUN bash -c "\
    cd ${BENCHMARK_DIR} && \
    for file in CAM_ABS_DATA.DBL CAM_AEROPT_DATA.DBL GENPARM.TBL LANDUSE.TBL NoahmpTable.TBL \
                OZONE_DAT.DBL OZONE_LAT.TBL OZONE_PLEV.TBL OZONE_TBL \
                RRTMG_LW_DATA RRTMG_LW_DATA.DBL RRTMG_SW_DATA RRTMG_SW_DATA.DBL \
                SOILPARM.TBL VEGPARM.TBL atmosphere_model; do \
        if [ -e ${MPAS_DIR}/\$file ]; then \
            ln -sf ${MPAS_DIR}/\$file .; \
        else \
            echo \"não encontrado\"; \
        fi; \
    done \
"

WORKDIR ${BENCHMARK_DIR}
ENTRYPOINT ["/bin/bash"]
