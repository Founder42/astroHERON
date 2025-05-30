#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
update=""
manual="RGS: Add contamination bkg source to source list. label ra dec must be specified during execution, e.g. './rgs_custom_srcPSF.sh label ra dec'"
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

    # Add contamination sources
    rgssources srclist=`ls *R1S*SRC*0000.FIT` addusersource=yes label=$1 ra=$2 dec=$3 bkgexclude=yes
    rgssources srclist=`ls *R2S*SRC*0000.FIT` addusersource=yes label=$1 ra=$2 dec=$3 bkgexclude=yes

done