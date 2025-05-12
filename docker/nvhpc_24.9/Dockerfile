# Etapa 1: Base NVIDIA com NVHPC
FROM nvcr.io/nvidia/nvhpc:24.9-devel-cuda12.6-ubuntu22.04

# Ambiente interativo não-interruptivo e shell padrão bash
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Variáveis de diretórios principais
ENV MPAS_DIR=/home/monan/MPAS-Model_v8.2.2_tempohpc \
    BENCHMARK_DIR=/home/monan/MPAS-A_benchmark_120km_v7.0

# Instalar dependências do sistema
RUN apt update -y
RUN apt upgrade -y
RUN apt install -y \
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

# Criar usuário e home
RUN adduser --disabled-password --gecos "" monan
USER monan
WORKDIR /home/monan

# Baixar e descompactar Spack
RUN wget https://github.com/spack/spack/releases/download/v0.23.1/spack-0.23.1.tar.gz
RUN tar zxvf spack-0.23.1.tar.gz

# Clonar o repositório MPAS
RUN git clone --single-branch --branch branch_v8.2.2 https://github.com/TempoHPC/MPAS-Model.git ${MPAS_DIR}

# Configurar ambiente, instalar via Spack e compilar MPAS
RUN echo $USER
RUN echo $HOME

RUN source /usr/share/modules/init/bash && \
    module use /opt/nvidia/hpc_sdk/modulefiles && \
    module load nvhpc-openmpi3/24.9 && \
    source /home/monan/spack-0.23.1/share/spack/setup-env.sh && \
    spack compiler find && \
    spack external find m4 perl cmake openmpi bzip2 && \
    spack install parallelio%nvhpc@=24.9 ^parallel-netcdf ^netcdf-c@4.9.2~blosc~zstd

RUN source /usr/share/modules/init/bash && \
    module use /opt/nvidia/hpc_sdk/modulefiles && \
    module load nvhpc-openmpi3/24.9 && \
    source /home/monan/spack-0.23.1/share/spack/setup-env.sh && \
    export NETCDF=$(spack location -i netcdf-fortran) && \
    export PNETCDF=$(spack location -i parallel-netcdf) && \
    ln -sf $(spack location -i netcdf-c)/lib/libnetcdf* ${NETCDF}/lib/

RUN cd ${MPAS_DIR}
RUN git pull
RUN make CORE=atmosphere clean
RUN make -j 8 pgi CORE=atmosphere USE_PIO=false OPENACC=true OPENMP=true PRECISION=single 2>&1 | tee make.output

# Baixar benchmark e extrair
RUN wget https://www2.mmm.ucar.edu/projects/mpas/benchmark/v7.0/MPAS-A_benchmark_120km_v7.0.tar.gz
RUN tar -xvzf MPAS-A_benchmark_120km_v7.0.tar.gz

# Remover arquivos não utilizados
RUN find ${BENCHMARK_DIR} -maxdepth 1 \( -name "*.TBL" -o -name "*.DBL" -o -name "RRTMG*" \) -exec rm -f {} \;

# Cria links simbólicos para arquivos do MPAS-Model
RUN cd ${BENCHMARK_DIR} && \
    if [ -e ${MPAS_DIR}/CAM_ABS_DATA.DBL ]; then ln -sf ${MPAS_DIR}/CAM_ABS_DATA.DBL .; else echo "CAM_ABS_DATA.DBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/CAM_AEROPT_DATA.DBL ]; then ln -sf ${MPAS_DIR}/CAM_AEROPT_DATA.DBL .; else echo "CAM_AEROPT_DATA.DBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/GENPARM.TBL ]; then ln -sf ${MPAS_DIR}/GENPARM.TBL .; else echo "GENPARM.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/LANDUSE.TBL ]; then ln -sf ${MPAS_DIR}/LANDUSE.TBL .; else echo "LANDUSE.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/NoahmpTable.TBL ]; then ln -sf ${MPAS_DIR}/NoahmpTable.TBL .; else echo "NoahmpTable.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/OZONE_DAT.DBL ]; then ln -sf ${MPAS_DIR}/OZONE_DAT.DBL .; else echo "OZONE_DAT.DBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/OZONE_LAT.TBL ]; then ln -sf ${MPAS_DIR}/OZONE_LAT.TBL .; else echo "OZONE_LAT.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/OZONE_PLEV.TBL ]; then ln -sf ${MPAS_DIR}/OZONE_PLEV.TBL .; else echo "OZONE_PLEV.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/OZONE_TBL ]; then ln -sf ${MPAS_DIR}/OZONE_TBL .; else echo "OZONE_TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/RRTMG_LW_DATA ]; then ln -sf ${MPAS_DIR}/RRTMG_LW_DATA .; else echo "RRTMG_LW_DATA não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/RRTMG_LW_DATA.DBL ]; then ln -sf ${MPAS_DIR}/RRTMG_LW_DATA.DBL .; else echo "RRTMG_LW_DATA.DBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/RRTMG_SW_DATA ]; then ln -sf ${MPAS_DIR}/RRTMG_SW_DATA .; else echo "RRTMG_SW_DATA não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/RRTMG_SW_DATA.DBL ]; then ln -sf ${MPAS_DIR}/RRTMG_SW_DATA.DBL .; else echo "RRTMG_SW_DATA.DBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/SOILPARM.TBL ]; then ln -sf ${MPAS_DIR}/SOILPARM.TBL .; else echo "SOILPARM.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/VEGPARM.TBL ]; then ln -sf ${MPAS_DIR}/VEGPARM.TBL .; else echo "VEGPARM.TBL não encontrado"; fi && \
    if [ -e ${MPAS_DIR}/atmosphere_model ]; then ln -sf ${MPAS_DIR}/atmosphere_model .; else echo "atmosphere_model não encontrado"; fi


# Definir diretório de trabalho e copiar script
WORKDIR ${BENCHMARK_DIR}
COPY run_mpas.sh ${BENCHMARK_DIR}

# Shell interativo padrão
ENTRYPOINT ["/bin/bash"]
