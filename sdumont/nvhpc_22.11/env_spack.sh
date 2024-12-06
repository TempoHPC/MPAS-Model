#!/bin/bash
workdir=/scratch/cenapadrjsd/rpsouto
version=v0.18.1
spackdir=${workdir}/spack/sequana/${version}
. ${spackdir}/share/spack/setup-env.sh

export SPACK_USER_CONFIG_PATH=${workdir}/spack/sequana/.spack/${version}

spack env activate -p monan
