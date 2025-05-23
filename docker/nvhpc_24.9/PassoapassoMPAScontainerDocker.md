## Passo a passo para rodar MPAS no container Docker

```bash
$ git clone https://github.com/TempoHPC/MPAS-Model.git
$ cd MPAS-Model
```

Precisa estar na branch: **branch_v8.2.2**

```bash
$ git branch #verifica em qual branch está
$ git chekout branch_v8.2.2 #muda para a branch branch_v8.2.2
```

Após isso, entrar no diretório onde estão os arquivos

```bash
$ cd docker/nvhpc_24.9
$ ls -ltr
```

Entre os arquivos, devem conter os seguintes:

> **MPAS_v8.2.2.dockerfile**
>
> **run_mpas.sh**

**MPAS_v8.2.2.dockerfile**

```bash
# docker build --no-cache -t mpas:8.2.2 -f MPAS_v8.2.2.dockerfile .
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
WORKDIR ${BENCHMARK_DIR}
RUN sed -i "s/config_run_duration = '3_00:00:00'/config_run_duration = '0_03:00:00'/g" namelist.atmosphere

#Linkar arquivos do modelo
RUN bash -c "\
    cd ${BENCHMARK_DIR} && \
    cp ../MPAS-Model_v8.2.2_tempohpc/docker/nvhpc_24.9/run_mpas.sh . && \
    for file in CAM_ABS_DATA.DBL CAM_AEROPT_DATA.DBL GENPARM.TBL LANDUSE.TBL NoahmpTable.TBL \
                OZONE_DAT.DBL OZONE_LAT.TBL OZONE_DAT.TBL OZONE_PLEV.TBL OZONE_TBL \
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
```

**run_mpas.sh**

```bash
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
        ./atmosphere_model 2>&1 | tee run_mpas${ntasks}.out
```

No local do arquivo no terminal, execute o comando abaixo parar criar a imagem a partir do script **MPAS_v8.2.2.dockerfile**:

```bash
$ docker build -t mpas:8.2.2 -f MPAS_v8.2.2.dockerfile .
```

Caso tenha feito tentativas anteriores que resultaram em erro, utilize a opção **`--no-cache`** para forçar a criação da imagem do zero, ignorando qualquer cache de etapas anteriores

```bash
$ docker build --no-cache -t mpas:8.2.2 -f MPAS_v8.2.2.dockerfile .
```

Para visualizar a imagem criada utilize:

```bash
$ docker images
```

Aparecerá algo como:

```bash
REPOSITORY   TAG        IMAGE ID       CREATED       SIZE
mpas         8.2.2      6c523f9c83ee   2 days ago    15.2GB
mpas         8.2.2-v3   77ab70c7690d   2 days ago    15.2GB
<none>       <none>     2b5b3d82a4a6   13 days ago   15.2GB
```

A imagem criada pode ser identificada pelo nome e versão (REPOSITORY e TAG) que definimos com a opção -t. No exemplo abaixo, o nome da imagem é ***mpas*** e a tag (versão) é ***8.2.2*** :

*docker build --no-cache -t **mpas:8.2.2** -f MPAS_v8.2.2.dockerfile .*

Após a criação da imagem, utilizamos o comando **`docker run`** para instanciar, ou seja, iniciar um container baseado nessa imagem:

```bash
$ docker run -it --entrypoint bash mpas:8.2.2
```

Ao executar este comando, entramos no container no diretório **/home/monan/MPAS-A_benchmark_120km_v7.0**
Para conferir os arquivos presentes, utilize o comando :

```bash
$ ls -ltr
```

Precisa aparecer os seguintes arquivos:

```bash
monan@8a748bec5eec:~/MPAS-A_benchmark_120km_v7.0$ ls -ltr
total 372664
-rw-r--r-- 1 monan monan   2252829 Jun  4  2013 x1.40962.graph.info
-rw-r--r-- 1 monan monan 379320020 Jun 20  2019 x1.40962.init.nc
-rw-r--r-- 1 monan monan       927 Jun 21  2019 stream_list.atmosphere.output
-rw-r--r-- 1 monan monan      1203 Jun 21  2019 stream_list.atmosphere.diagnostics
-rw-r--r-- 1 monan monan         9 Jun 21  2019 stream_list.atmosphere.surface
-rw-r--r-- 1 monan monan      1578 Jun 21  2019 streams.atmosphere
-rw-r--r-- 1 monan monan      1774 May 22 17:08 namelist.atmosphere
-rw-r--r-- 1 monan monan       711 May 22 17:08 run_mpas.sh
lrwxrwxrwx 1 monan monan        50 May 22 17:08 GENPARM.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/GENPARM.TBL
lrwxrwxrwx 1 monan monan        58 May 22 17:08 CAM_AEROPT_DATA.DBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/CAM_AEROPT_DATA.DBL
lrwxrwxrwx 1 monan monan        55 May 22 17:08 CAM_ABS_DATA.DBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/CAM_ABS_DATA.DBL
lrwxrwxrwx 1 monan monan        52 May 22 17:08 RRTMG_SW_DATA -> /home/monan/MPAS-Model_v8.2.2_tempohpc/RRTMG_SW_DATA
lrwxrwxrwx 1 monan monan        56 May 22 17:08 RRTMG_LW_DATA.DBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/RRTMG_LW_DATA.DBL
lrwxrwxrwx 1 monan monan        52 May 22 17:08 RRTMG_LW_DATA -> /home/monan/MPAS-Model_v8.2.2_tempohpc/RRTMG_LW_DATA
lrwxrwxrwx 1 monan monan        53 May 22 17:08 OZONE_PLEV.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/OZONE_PLEV.TBL
lrwxrwxrwx 1 monan monan        52 May 22 17:08 OZONE_LAT.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/OZONE_LAT.TBL
lrwxrwxrwx 1 monan monan        52 May 22 17:08 OZONE_DAT.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/OZONE_DAT.TBL
lrwxrwxrwx 1 monan monan        54 May 22 17:08 NoahmpTable.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/NoahmpTable.TBL
lrwxrwxrwx 1 monan monan        50 May 22 17:08 LANDUSE.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/LANDUSE.TBL
lrwxrwxrwx 1 monan monan        55 May 22 17:08 atmosphere_model -> /home/monan/MPAS-Model_v8.2.2_tempohpc/atmosphere_model
lrwxrwxrwx 1 monan monan        50 May 22 17:08 VEGPARM.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/VEGPARM.TBL
lrwxrwxrwx 1 monan monan        51 May 22 17:08 SOILPARM.TBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/SOILPARM.TBL
lrwxrwxrwx 1 monan monan        56 May 22 17:08 RRTMG_SW_DATA.DBL -> /home/monan/MPAS-Model_v8.2.2_tempohpc/RRTMG_SW_DATA.DBL

```

Após isso podemos fazer a execução do mpas

```bash
$ source ./run_mpas.sh 1 1
```

Saída na tela pós execução:

```bash
NETCDF: /home/monan/spack-0.23.1/opt/spack/linux-ubuntu22.04-skylake/nvhpc-24.9/netcdf-fortran-4.6.1-a3jbwgai5cqqa42ejyhwwjtbk75ncyib
PNETCDF: /home/monan/spack-0.23.1/opt/spack/linux-ubuntu22.04-skylake/nvhpc-24.9/parallel-netcdf-1.12.3-i4a5qjnargz6gdx6367jkrxqcbu2eir5
/home/monan/spack-0.23.1/opt/spack/linux-ubuntu22.04-skylake/nvhpc-24.9/netcdf-fortran-4.6.1-a3jbwgai5cqqa42ejyhwwjtbk75ncyib/lib:/home/monan/spack-0.23.1/opt/spack/linux-ubuntu22.04-skylake/nvhpc-24.9/parallel-netcdf-1.12.3-i4a5qjnargz6gdx6367jkrxqcbu2eir5/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/comm_libs/openmpi/openmpi-3.1.5/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/compilers/extras/qd/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/comm_libs/nvshmem/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/comm_libs/nccl/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/math_libs/lib64:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/compilers/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/24.9/cuda/lib64:
Warning: ieee_invalid is signaling
Warning: ieee_divide_by_zero is signaling
Warning: ieee_underflow is signaling
Warning: ieee_inexact is signaling
FORTRAN STOP

```

Irá gerar os arquivos **log.atmosphere.0000.out** e **run_mpas.out**

**log.atmosphere.0000.out**

```bash
$ tail -43 log.atmosphere.0000.out


    timer_name                                            total       calls        min            max            avg      pct_tot   pct_par     par_eff
  1 total time                                         341.26804         1      341.26804      341.26804      341.26804   100.00       0.00       1.00
  2  initialize                                          9.58603         1        9.58603        9.58603        9.58603     2.81       2.81       1.00
  3   read_ICs                                           4.00098         1        4.00098        4.00098        4.00098     1.17      41.74       1.00
  2  diagnostic_fields                                   0.19790        32        0.00032        0.01887        0.00618     0.06       0.06       1.00
  2  stream_output                                       0.00004        16        0.00000        0.00001        0.00000     0.00       0.00       1.00
  2  time integration                                  331.41107        15       17.11478       52.05458       22.09407    97.11      97.11       1.00
  3   physics driver                                   127.26807        15        4.04268       37.52629        8.48454    37.29      38.40       1.00
  4    calc_cldfraction                                  0.08378         2        0.03147        0.05231        0.04189     0.02       0.07       1.00
  4    rrtmg_swrad                                      33.70877         2       16.58254       17.12623       16.85439     9.88      26.49       1.00
  4    rrtmg_lwrad                                      30.21814         2       14.40738       15.81076       15.10907     8.85      23.74       1.00
  4    sf_monin_obukhov_rev                              1.08554        15        0.07014        0.07998        0.07237     0.32       0.85       1.00
  4    sf_noah                                           0.38937        15        0.02555        0.02787        0.02596     0.11       0.31       1.00
  4    bl_ysu                                           10.69976        15        0.69727        0.76666        0.71332     3.14       8.41       1.00
  4    bl_gwdo                                           2.31859        15        0.15186        0.15887        0.15457     0.68       1.82       1.00
  4    cu_ntiedtke                                      29.14532        15        1.91444        1.98998        1.94302     8.54      22.90       1.00
  3   atm_rk_integration_setup                           1.94789        15        0.07648        0.85509        0.12986     0.57       0.59       1.00
  3   atm_compute_moist_coefficients                     1.16048        15        0.06890        0.18133        0.07737     0.34       0.35       1.00
  3   physics_get_tend                                   1.53080        15        0.09819        0.12356        0.10205     0.45       0.46       1.00
  3   atm_compute_vert_imp_coefs                         2.50369        45        0.02341        1.45179        0.05564     0.73       0.76       1.00
  3   atm_compute_dyn_tend                              32.14883       135        0.19238        0.36474        0.23814     9.42       9.70       1.00
  3   small_step_prep                                    2.69869       135        0.01948        0.02942        0.01999     0.79       0.81       1.00
  3   atm_advance_acoustic_step                          9.83620       180        0.05024        0.06963        0.05465     2.88       2.97       1.00
  3   atm_divergence_damping_3d                          1.87708       180        0.01009        0.01422        0.01043     0.55       0.57       1.00
  3   atm_recover_large_step_variables                   7.35196       135        0.05183        0.05898        0.05446     2.15       2.22       1.00
  3   atm_compute_solve_diagnostics                     12.46515       135        0.08380        0.11006        0.09233     3.65       3.76       1.00
  3   atm_rk_dynamics_substep_finish                     2.29162        45        0.03473        0.06189        0.05092     0.67       0.69       1.00
  3   atm_advance_scalars                               11.00382        30        0.36254        0.37554        0.36679     3.22       3.32       1.00
  4    atm_advance_scalars [ACC_data_xfer]               0.00025        90        0.00000        0.00001        0.00000     0.00       0.00       1.00
  3   atm_advance_scalars_mono                          22.93891        15        1.50486        1.67050        1.52926     6.72       6.92       1.00
  4    atm_advance_scalars_mono [ACC_data_xfer]          0.00070       255        0.00000        0.00008        0.00000     0.00       0.00       1.00
  3   microphysics                                      91.40466        15        5.50383        6.58242        6.09364    26.78      27.58       1.00
  4    mp_wsm6                                          70.74831        15        4.09434        5.10144        4.71655    20.73      77.40       1.00

 -----------------------------------------
 Total log messages printed:
    Output messages =                  784
    Warning messages =                   5
    Error messages =                     0
    Critical error messages =            0
 -----------------------------------------

```

Para sair do container:

```bash
$ exit
```

Ao usar o comando **exit**, você sai do container, mas ele não é removido, ele apenas é interrompido e entra no estado exited (parado).
Isso significa que ele ainda existe e pode ser acessado novamente a qualquer momento.
Para visualizar os containers existentes (em execução ou parados), utilize o comando abaixo:

```bash
$ docker ps -a #visualizar containers existentes
CONTAINER ID   IMAGE           COMMAND   CREATED       STATUS                       PORTS   NAMES
cb292ef2cdfe   mpas:8.2.2      "bash"    2 days ago    Exited (255) 8 minutes ago           vigorous_wiles
b9f80a1308ac   mpas:8.2.2-v3   "bash"    2 days ago    Exited (127) 2 days ago              objective_jones
0c5d0684fa02   2b5b3d82a4a6    "bash"    13 days ago   Exited (255) 10 days ago             vigilant_ganguly
```

Para executarmos o container novamente, utilizamos o comando:

```bash
$ docker start <container_name> 
$ docker exec -i -t <container_name> bash
```

obs.: o nome dos containers são gerados aleatoriamente. Aparecem na coluna NAMES:

```bash
CONTAINER ID   IMAGE           COMMAND   CREATED       STATUS                       PORTS     NAMES
cb292ef2cdfe   mpas:8.2.2      "bash"    2 days ago    Exited (255) 8 minutes ago             vigorous_wiles
```

Exemplo:

```bash
$ docker exec -i -t vigorous_wiles bash
```

Também é possível visualizar apenas containers que estão em execução:

```bash
$ docker ps
```

Outros comandos importantes:

Excluir um container:

```bash
$ docker rm <containerID> 
```

Excluir uma imagem:

```bash
$ docker rmi <imageID> 
```

Obs.: Só é possível excluir uma imagem se não existirem containers criados a partir dela. Caso existam, é necessário remover os containers antes de excluir a imagem.

## **Adicionar arquivos para execução com mais processos**

Baixar arquivos da pasta : https://drive.google.com/drive/folders/1lRW5oPwfkjWr6n5BwQgEnqrm4hBblXTT?usp=sharing e adiciona-los na pasta onde está o dockerfile

Com o container em execução, abra outra aba do terminal (fora do container) e execute os comandos abaixo para copiar os arquivos desejados para dentro do container:

```bash
$ docker cp /caminho/do/arquivo/x1.40962.grid.nc <container ID>:/home/monan/MPAS-A_benchmark_120km_v7.0
```

```bash
$ docker cp /caminho/do/arquivo/x1.40962.graph.info.part.2  <container ID>:/home/monan/MPAS-A_benchmark_120km_v7.0
```

Repita o procedimento acima para os demais arquivos que precisam ser copiados para o container.
