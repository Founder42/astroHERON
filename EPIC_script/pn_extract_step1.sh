#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="Everything on PN reprocessing from unzip to raw epproc. Attention: You shall manually check the generated file *ImagingEvts.ds* and determine which one to use."
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

#obsid=("0723450101")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    # If you haven't unzip file, please uncomment these
    #tar zxvf `ls *.gz`
    #tar xvf `ls *.TAR`

    #export SAS_ODF=`pwd`
    #cifbuild
    export SAS_CCF=`pwd`/ccf.cif
    #odfingest
    export SAS_ODF=`pwd`/`ls *SUM.SAS`
    
    # assign certain reference points
    epproc referencepointing=user ra=189.997458 dec=-11.623056 >& raw_epproc_log

    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done
