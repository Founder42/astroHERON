#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
update=""
manual="RGS Change source enclosed PSF and check new regions. Must be excecuted after 'rgs_custom_bkgAvoid.sh' if needed. PSF for src and bkg must be specified during execution, e.g. './rgs_custom_srcPSF.sh 90 95'."
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

#obsid=("0110910201")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`

    #change src extraction PSF
    rgsregions srclist=`ls *R1S*SRC*0000.FIT` evlist=`ls *R1S*EVEN*` xpsfbelow=$1 xpsfabove=$1 xpsfexcl=$2 procsrcsexpr='INDEX==3'
    rgsregions srclist=`ls *R2S*SRC*0000.FIT` evlist=`ls *R2S*EVEN*` xpsfbelow=$1 xpsfabove=$1 xpsfexcl=$2 procsrcsexpr='INDEX==3'

    # generate new src and bkg regions for check
    cxctods9 table=`ls *R1S*SRC*0000.FIT`':RGS1_SRC3_SPATIAL' regtype=linear -V 0 > rgs1_src_custom.reg
    cxctods9 table=`ls *R1S*SRC*0000.FIT`':RGS1_BACKGROUND' regtype=linear -V 0 > rgs1_bkg_custom.reg

done