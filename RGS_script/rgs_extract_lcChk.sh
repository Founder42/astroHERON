#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="RGS Checking: generate flaring particle bkg light curve"
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

obsid=("0084030101" "0900170101")
#obsid=("0723450101" "0723450201" "0729561001" "0729561201" "0761620101" "0761620201")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`
    #rgsproc withsrc=yes srclabel=M83N srcra=204.2524 srcdec=-29.866 >& cen_rgsproc_log

    src1=$(ls *R1S*SRC*)
    src2=$(ls *R2S*SRC*)
    
    evselect table=`ls *R1S*EVEN*` timebinsize=100 rateset=rgs1_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR))"
    evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done
