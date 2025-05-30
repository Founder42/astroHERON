#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="Everything on rgs reprocessing from unzip to raw rgsproc"
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

#obsid=("0723450101")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    tar zxvf `ls *.gz`
    tar xvf `ls *.TAR`

    export SAS_ODF=`pwd`
    cifbuild
    export SAS_CCF=`pwd`/ccf.cif
    odfingest
    export SAS_ODF=`pwd`/`ls *SUM.SAS`
    rgsproc >& raw_rgsproc_log

    #src1=$(ls *R1S*SRC*)
    #src2=$(ls *R2S*SRC*)
    #evselect table=`ls *R1S*EVEN*` timebinsize=100 rateset=rgs1_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR))"
    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done
