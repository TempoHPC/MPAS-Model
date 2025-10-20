# Instalação do MPAS e do MONAN no SDumont (sequana)


## Acesso ao SDumont
- Fazer login no SDumont

  ```bash
  ssh <username>@login.sdumont.lncc.br
  cd $SCRATCH
  ```


# Como Compilar o Modelo MPAS

## Baixar o  modelo MPAS

Baixando o código-fonte a partir do *fork* do repositório Git do MPAS, utilizando *branch* relativo a versão 8.2.2:

```bash
$ git clone --single-branch --branch branch_v8.2.2 https://github.com/TempoHPC/MPAS-Model.git MPAS-Model_v8.2.2_tempohpc_scalasca
$ cd MPAS-Model_v8.2.2_tempohpc_scalasca
```

## Compilando o modelo MPAS


## Preparação do ambiente

- Carregar os arquivos de configuração do ambiente e do spack, que estão na pasta `sdumont/openmpi_4.1.4` do repositório git.
  
- Carregar o arquivo `env_sequana_openmpi414.sh` 

  ```bash
  #!/bin/bash
  
  #module load git/2.23_sequana
  module load python/3.9.1_sequana
  module load cmake/3.23.2_sequana
  module load openmpi/gnu/4.1.4+gcc-12.4+cuda-11.6_sequana
  ```
  
  ```bash
  $ source sdumont/openmpi_4.1.4/env_sequana_openmpi414.sh
```
- Carregar o arquivo `env_spack.sh` 

  ```bash
  #!/bin/bash
  workdir=/scratch/cenapadrjsd/rpsouto
  version=v0.18.1
  spackdir=${workdir}/spack/sequana/${version}
  . ${spackdir}/share/spack/setup-env.sh
  
  export SPACK_USER_CONFIG_PATH=${workdir}/spack/sequana/.spack/${version}
  
  spack env activate -p mpas_gcc12
```

  ```bash
  $ source sdumont/openmpi_4.1.4/env_spack.sh
  ```

- Que já carrega o *environment* monan:

  ```bash
  [mpas_gcc12]$
  ```

- Listar os pacotes instalados no *environment* monan do spack:

  ```bash
  [mpas_gcc12]$ spack find
  ==> In environment mpas_gcc12
  ==> Root specs
  -- no arch / gcc@12.4.0 -----------------------------------------
  hpctoolkit@2021.10.15%gcc@12.4.0  mpas-model%gcc@12.4.0  scalasca%gcc@12.4.0
  
  ==> 45 installed packages
  -- linux-rhel8-skylake_avx512 / gcc@12.4.0 ----------------------
  autoconf@2.69      diffutils@3.6          libiberty@2.37         netcdf-fortran@4.5.4    parallelio@2_5_4
  automake@1.16.1    dyninst@12.1.0         libmonitor@2021.11.08  numactl@2.0.14          perl@5.26.3
  binutils@2.30.119  elfutils@0.186         libtool@2.4.6          opari2@2.0.6            pkgconf@1.4.2
  boost@1.79.0       hdf5@1.12.2            libunwind@1.6.2        openjdk@11.0.15_10      python@3.9.1
  bzip2@1.0.8        hpctoolkit@2021.10.15  m4@1.4.18              openmpi@4.1.4           scalasca@2.6
  cmake@3.23.2       hpcviewer@2022.03      mbedtls@3.1.0          openssl@1.1.1o          scorep@7.0
  cubelib@4.6        intel-tbb@2020.3       memkind@1.13.0         otf2@2.3                xerces-c@3.2.3
  cubew@4.6          intel-xed@2022.04.17   mpas-model@7.1         papi@6.0.0.1            xz@5.2.5
  curl@7.83.0        libdwarf@20180129      netcdf-c@4.8.1         parallel-netcdf@1.12.2  zlib@1.2.12
  
  ```

- Carregar o pacote `scalasca`

  ```bash
  [mpas_gcc12]$ spack load scalasca
  ```

- Verifica se foi em carregado o pacote

  ```bash
  [mpas_gcc12]$ spack load --list
  ==> 10 loaded packages
  -- linux-rhel8-skylake_avx512 / gcc@12.4.0 ----------------------
  cubelib@4.6  opari2@2.0.6   otf2@2.3      pkgconf@1.4.2  scorep@7.0
  cubew@4.6    openmpi@4.1.4  papi@6.0.0.1  scalasca@2.6   zlib@1.2.12
  ```

  

- Executar o script para instalação do MPAS `sdumont/openmpi_4.1.4/make_mpas8_gnu_scalasca.sh`

- Que possui conteúdo a seguir, definindo as variáveis de ambiente `NETCDF` e `PNETCF`, e executando comando make com alguns parâmetros a serem seguidos na durante a compilação do código-fonte. O cabeçalho do script explica o significado de cada parâmetro. 

```bash
#!/bin/bash

#Usage: make target CORE=[core] [options]

#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi

#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test

#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.

#export PIO=$(spack location -i parallelio
export NETCDF=$(spack location -i netcdf-fortran)
export PNETCDF=$(spack location -i parallel-netcdf)

#make -j 8 [gfortran|ifort|pgi|xlf] CORE=atmosphere USE_PIO=false OPENMP=true PRECISION=single 2>&1 | tee make.output
#make -j 8 gfortran CORE=atmosphere USE_PIO=false OPENMP=true PRECISION=single 2>&1 | tee make.output
make -j 8 gfortran-scorep CORE=atmosphere USE_PIO=false OPENMP=true PRECISION=single 2>&1 | tee make.output
mv atmosphere_model atmosphere_model_scalasca
```

- Executa a instalação:

```bash
$ make CORE=atmosphere clean
$ source sdumont/openmpi_4.1.4/make_mpas8_gnu_scalasca.sh

....

make[2]: Leaving directory '/scratch/cenapadrjsd/rpsouto/monan/MPAS-Model_v8.2.2_tempohpc_scalasca/src/core_atmosphere'
*******************************************************************************
MPAS was built with default single-precision reals.
Debugging is off.
Parallel version is on.
Using the mpi module.
Papi libraries are off.
TAU Hooks are off.
MPAS was built with OpenMP enabled.
MPAS was built without OpenMP-offload GPU support.
MPAS was built without OpenACC accelerator support.
Position-dependent code was generated.
MPAS was built with .F files.
The native timer interface is being used
Using the SMIOL library.
*******************************************************************************
```

A mensagem final acima informa que a compilação foi bem-sucedida e alguns dos parâmetros de instalação que foram empregados. Os seguintes executáveis devem ter sido gerados: `atmosphere_model_scalaca` e `build_tables`, além do arquivo  `make.output`, contendo a saída em tela da compilação.  **É fundamental que os compiladores e bibliotecas sejam compatíveis, preferencialmente compilados com o mesmo compilador** para que não haja erros na montagem do modelo. 



