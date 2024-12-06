# Instalação do MPAS e do MONAN no SDumont (sequana)


## Acesso ao SDumont
- Fazer login no SDumont

  ```bash
  ssh <username>@146.134.143.248
  cd $SCRATCH
  ```


# Como Compilar o Modelo MPAS

## Baixar o  modelo MPAS

Baixando o código-fonte a partir do *fork* do repositório Git do MPAS, utilizando *branch* relativo a versão 8.1.0:

```bash
$ git clone --single-branch --branch branch_v8.1.0 https://github.com/TempoHPC/MPAS-Model.git MPAS-Model_v8.1.0_tempohpc
$ cd MPAS-Model_v8.1.0_tempohpc

$ git log
commit f084b36f8ac82eb1e76c426d3572339c36523c77 (grafted, HEAD -> branch_v8.1.0, tag: v8.1.0)
Author: Michael Duda <duda@ucar.edu>
Date:   Thu Apr 18 21:40:35 2024 +0000

    Merge branch 'release-v8.1.0'

    MPAS Version 8.1.0

    This release of MPAS introduces several updates and new capabilities for
    MPAS-Atmosphere, most notably:

```

## Compilando o modelo MPAS


## Preparação do ambiente

- Carregar os arquivos de configuração do ambiente e do spack, que estão na pasta `sdumont/nvhpc_22.11/` do repositório git.
  
- Carregar o arquivo `env_sequana_nvhpc.sh` 

  ```bash
  #!/bin/bash
  
  module load git/2.23_sequana
  module load python/3.9.1_sequana
  module load gcc/9.3_sequana
  module load cmake/3.23.2_sequana
  module use /scratch/cenapadrjsd/rpsouto/opt/nvidia/hpc_sdk/modulefiles
  module load nvhpc/22.11
  export NVLOCALRC=/scratch/cenapadrjsd/rpsouto/opt/nvidia/hpc_sdk/Linux_x86_64/localrc
  ```

  ```bash
  $ source sdumont/nvhpc_22.11/env_sequana_nvhpc.sh
  ```
- Carregar o arquivo `env_spack.sh` 

  ```bash
  #!/bin/bash
  workdir=/scratch/cenapadrjsd/rpsouto
  version=v0.18.1
  spackdir=${workdir}/spack/sequana/${version}
  . ${spackdir}/share/spack/setup-env.sh
  
  export SPACK_USER_CONFIG_PATH=${workdir}/spack/sequana/.spack/${version}
  
  spack env activate -p monan
  ```

  ```bash
  $ source sdumont/nvhpc_22.11/env_spack.sh
  ```

- Que já carrega o *environment* monan:

  ```bash
  [monan]$
  ```

- Listar os pacotes instalados no *environment* monan do spack:

  ```bash
  [monan]$ spack find
  ```

  

- Executar o script para instalação do MPAS `sdumont/nvhpc_22.11/make_mpas8_nvhpc.sh`

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

#export PIO=$(spack location -i parallelio)
export NETCDF=$(spack location -i netcdf-fortran)
export PNETCDF=$(spack location -i parallel-netcdf)

#make -j 8 [gfortran|ifort|pgi|xlf] CORE=atmosphere USE_PIO2=true PRECISION=single 2>&1 | tee make.output
make -j 8 pgi CORE=atmosphere USE_PIO=false OPENMP=true PRECISION=single 2>&1 | tee make.output
```

- Executa a instalação:

```bash
$ make CORE=atmosphere clean
$ source sdumont/nvhpc_22.11/make_mpas8_nvhpc.sh

....

make[2]: Leaving directory '/scratch/cenapadrjsd/rpsouto/monan/MPAS-Model_v8.1.0_tempohpc/src/core_atmosphere'
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

A mensagem final acima informa que a compilação foi bem-sucedida e alguns dos parâmetros de instalação que foram empregados. Os seguintes executáveis devem ter sido gerados: `atmosphere_model` e `build_tables`, além do arquivo  `make.output`, contendo a saída em tela da compilação.  **É fundamental que os compiladores e bibliotecas sejam compatíveis, preferencialmente compilados com o mesmo compilador** para que não haja erros na montagem do modelo. 

