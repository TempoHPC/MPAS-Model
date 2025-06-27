# docker build --no-cache -t mpas:8.2.2 -f MPAS_v8.2.2_novo.dockerfile .
# docker run --gpus all -it --entrypoint bash mpas:8.2.2

# Imagem base e configurações iniciais
FROM nvcr.io/nvidia/nvhpc:24.9-devel-cuda12.6-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

#Variáveis de diretório
ENV MPAS_DIR=/home/monan/MPAS-Model_v8.2.2_tempohpc \
    BENCHMARK_DIR=/home/monan/MPAS-A_benchmark_120km_v7.0

#Instalação de dependências do sistema
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
    wget \
    metis 

# Criação do usuário 
RUN adduser --disabled-password --gecos "" monan
USER monan
WORKDIR /home/monan

# Instalação do Spack
RUN wget https://github.com/spack/spack/releases/download/v0.23.1/spack-0.23.1.tar.gz && \
    tar zxvf spack-0.23.1.tar.gz

#Configuração do ambiente e instalação das bibliotecas com Spack
RUN echo $USER && \
    echo $HOME && \
    cd && \
    
    # Preparar os módulos 
    source /usr/share/modules/init/bash && \
    module use /opt/nvidia/hpc_sdk/modulefiles && \
    module load nvhpc-openmpi3/24.9 && \
    
    # Inicializar Spack 
    source /home/monan/spack-0.23.1/share/spack/setup-env.sh && \
    spack compiler find && \
    spack external find m4 perl cmake openmpi bzip2 && \
    
    # Instalar bibliotecas com Spack 
    spack install parallelio%nvhpc@=24.9 ^parallel-netcdf ^netcdf-c@4.9.2~blosc~zstd && \
    
    # Criar links para bibliotecas NetCDF 
    export NETCDF=$(spack location -i netcdf-fortran) && \
    export PNETCDF=$(spack location -i parallel-netcdf) && \
    ln -sf $(spack location -i netcdf-c)/lib/libnetcdf* ${NETCDF}/lib/ &&\
    
    #Clonagem do MPAS 
    git clone https://github.com/TempoHPC/MPAS-Model.git ${MPAS_DIR} && \
    
    # Compilação do MPAS 
    cd ${MPAS_DIR} && \
    make CORE=atmosphere clean && \
    make -j 4 pgi CORE=atmosphere USE_PIO=false OPENACC=true OPENMP=true PRECISION=single 2>&1 | tee make.output


#Download e preparação do benchmark 
WORKDIR /home/monan
RUN wget https://www2.mmm.ucar.edu/projects/mpas/benchmark/v7.0/MPAS-A_benchmark_120km_v7.0.tar.gz && \
    tar -xvzf MPAS-A_benchmark_120km_v7.0.tar.gz

# Remoção de arquivos desnecessários 
RUN find ${BENCHMARK_DIR} -maxdepth 1 \( -name "*.TBL" -o -name "*.DBL" -o -name "RRTMG*" \) -exec rm -f {} \;

# Edição do namelist e criação das partições com METIS 
WORKDIR ${BENCHMARK_DIR}
RUN sed -i "s/config_run_duration = '3_00:00:00'/config_run_duration = '0_03:00:00'/g" namelist.atmosphere && \
    gpmetis -minconn -contig -niter=200 x1.40962.graph.info 2 && \
    gpmetis -minconn -contig -niter=200 x1.40962.graph.info 4 && \
    gpmetis -minconn -contig -niter=200 x1.40962.graph.info 8 && \
    gpmetis -minconn -contig -niter=200 x1.40962.graph.info 16

# Link de arquivos necessários do MPAS para o diretório de benchmark 
RUN bash -c "\
    cd ${BENCHMARK_DIR} && \
    cp ../MPAS-Model_v8.2.2_tempohpc/run_mpas.sh . && \
    for file in CAM_ABS_DATA.DBL CAM_AEROPT_DATA.DBL GENPARM.TBL LANDUSE.TBL NoahmpTable.TBL \
                OZONE_DAT.DBL OZONE_LAT.TBL OZONE_DAT.TBL OZONE_PLEV.TBL OZONE_TBL \
                RRTMG_LW_DATA RRTMG_LW_DATA.DBL RRTMG_SW_DATA RRTMG_SW_DATA.DBL \
                SOILPARM.TBL VEGPARM.TBL atmosphere_model; do \
        if [ -e ${MPAS_DIR}/\$file ]; then \
            ln -sf ${MPAS_DIR}/\$file .; \
        else \
            echo \"não encontrado\"; \
        fi; \
    done"

# Diretório de trabalho padrão

WORKDIR ${BENCHMARK_DIR}

ENTRYPOINT ["/bin/bash"]
