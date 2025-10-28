# Instalação do MPAS e do MONAN no SDumont (sequana)


## Acesso ao SDumont
- Fazer login no SDumont

  ```bash
  ssh <username>@login.sdumont.lncc.br
  cd $SCRATCH
  ```


# Como Executar o Modelo MPAS

## *Templates*

Foram criados *templates* para execução de *benchmarks* do MPAS, que estão na pasta `/scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/dyncore/mpas/benchmark/v8.0/`:

```bash
MPAS-A_benchmark_120km_v8.0_template/
MPAS-A_benchmark_60km_v8.0_template/
```

Essas pastas contém todos os arquivos necessários para realizar a execução de uma instância do modelo MPAS v8.x.x

```bash
.
├── TBLv8.0
├── VEGPARM.TBL -> TBLv8.0/VEGPARM.TBL
├── CAM_ABS_DATA.DBL -> TBLv8.0/CAM_ABS_DATA.DBL
├── CAM_AEROPT_DATA.DBL -> TBLv8.0/CAM_AEROPT_DATA.DBL
├── GENPARM.TBL -> TBLv8.0/GENPARM.TBL
├── LANDUSE.TBL -> TBLv8.0/LANDUSE.TBL
├── NoahmpTable.TBL -> TBLv8.0/NoahmpTable.TBL
├── OZONE_DAT.TBL -> TBLv8.0/OZONE_DAT.TBL
├── OZONE_LAT.TBL -> TBLv8.0/OZONE_LAT.TBL
├── OZONE_PLEV.TBL -> TBLv8.0/OZONE_PLEV.TBL
├── RRTMG_LW_DATA -> TBLv8.0/RRTMG_LW_DATA
├── RRTMG_LW_DATA.DBL -> TBLv8.0/RRTMG_LW_DATA.DBL
├── RRTMG_SW_DATA -> TBLv8.0/RRTMG_SW_DATA
├── RRTMG_SW_DATA.DBL -> TBLv8.0/RRTMG_SW_DATA.DBL
├── SOILPARM.TBL -> TBLv8.0/SOILPARM.TBL

├── metis.sh
├── x1.40962.graph.info
├── x1.40962.graph.info.part.16
├── x1.40962.graph.info.part.2
├── x1.40962.graph.info.part.32
├── x1.40962.graph.info.part.4
├── x1.40962.graph.info.part.64
├── x1.40962.graph.info.part.8
└── x1.40962.init.nc -> /scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/dyncore/mpas/benchmark/v8.0/x1.init.nc/x1.40962.init.nc

├── namelist.atmosphere
├── stream_list.atmosphere.diagnostics
├── stream_list.atmosphere.output
├── stream_list.atmosphere.surface
├── streams.atmosphere

├── atmosphere_model -> /scratch/cenapadrjsd/rpsouto/projetos/tempohpc/github/MPAS-Model_v8.2.2_gnu/atmosphere_model
├── atmosphere_model_scalasca -> /scratch/cenapadrjsd/rpsouto/projetos/tempohpc/github/MPAS-Model_v8.2.2_gnu_scalasca/atmosphere_model_scalasca

├── submit_atmosphere_v8_gnu.srm -> /scratch/cenapadrjsd/rpsouto/projetos/tempohpc/github/MPAS-Model_v8.2.2_gnu/sdumont/openmpi_4.1.4/submit_atmosphere_v8_gnu.srm
├── submit_atmosphere_v8_gnu_hpctoolkit.srm -> /scratch/cenapadrjsd/rpsouto/projetos/tempohpc/github/MPAS-Model_v8.2.2_gnu/sdumont/openmpi_4.1.4/submit_atmosphere_v8_gnu_hpctoolkit.srm
├── submit_atmosphere_v8_gnu_scalasca.srm -> /scratch/cenapadrjsd/rpsouto/projetos/tempohpc/github/MPAS-Model_v8.2.2_gnu/sdumont/openmpi_4.1.4/submit_atmosphere_v8_gnu_scalasca.srm
```



## Utilizando os *templates*

- Copiar os templates para sua pasta no SDumont

  ```bash
  $ cd $SCRATCH
  $ mkdir -p rodadas/mpas-v8.2.2
  $ cd rodadas/mpas-v8.2.2
  $ cp -r -p /scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/dyncore/mpas/benchmark/v8.0/MPAS-A_benchmark_120km_v8.0_template/ MPAS-A_benchmark_120km_v8.0_gnu 
  $ cp -r -p /scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/dyncore/mpas/benchmark/v8.0/MPAS-A_benchmark_60km_v8.0_template/ MPAS-A_benchmark_60km_v8.0_gnu
  ```

- Rodar um exemplo para 120km em paralelo, usando 8 processos MPI, em um único nó:

  ```bash
  $ sbatch -N1 -n8 -c1 -p sequana_gpu --time=01:00:00 submit_atmosphere_v8_gnu.srm
  Submitted batch job 11408154
  ```

  O tempo de integração (simulação) padrão das rodadas é de 2hs, conforme definido no campo `config_run_duration`do arquivo `namelist.atmosphere`:

  ```bash
  config_run_duration = '0_02:00:00'
  ```

  As saídas da rodada estarão armazenadas em uma pasta com caminho similar ao exemplo a seguir:

  ```bash
  results/partition-sequana_gpu/NUMNODES-1/MPI-8/OMP-1/JOBID-11408149/
  ├── log.atmosphere.0000.out
  └── slurm-11408149.out
  ```


  O mesmo procedimento deve ser realizado para rodar o script das rodadas que empregam as ferramentas de avaliação de desempenho:
  ***HPCTookit***

  ```bash
  $ sbatch -N1 -n8 -c1 -p sequana_gpu --time=01:00:00 submit_atmosphere_v8_gnu_hpctoolkit.srm
  Submitted batch job 11408155
  ```

  As saídas da rodada estarão armazenadas em uma pasta com caminho similar ao exemplo a seguir:

  ```bash
  results_hpctoolkit/partition-sequana_gpu/NUMNODES-1/MPI-8/OMP-1/JOBID-11408155/
  ├── atmosphere_model.hpcstruct
  ├── hpctoolkit-atmosphere_model-database-11408155
  ├── hpctoolkit-atmosphere_model-measurements-11408155
  ├── log.atmosphere.0000.out
  └── slurm-11408155.out
  
  ```

  ***Scalasca***

  ```bash
  $ sbatch -N1 -n8 -c1 -p sequana_gpu --time=01:00:00 submit_atmosphere_v8_gnu_scalasca.srm 
  Submitted batch job 11408162
  ```

  As saídas da rodada estarão armazenadas em uma pasta com caminho similar ao exemplo a seguir:

  ```
  results_scalasca/partition-sequana_gpu/NUMNODES-1/MPI-8/OMP-1/JOBID-11408162/
  ├── log.atmosphere.0000.out
  ├── scorep_atmosphere_model_scalasca_8x1_sum
  │   ├── MANIFEST.md
  │   ├── profile.cubex
  │   ├── scorep.cfg
  │   ├── scorep.log
  │   ├── scorep.score
  │   └── summary.cubex
  └── slurm-11408162.out
  ```

  

