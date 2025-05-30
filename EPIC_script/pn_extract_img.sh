#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="Extract PN image for source region check."
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

#obsid=("0723450101")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`

    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`
    
    # assign certain reference points
    evselect table='pn_'$x'_clean.fits' imagebinning=binSize imageset='pn_'$x'.fits' withimageset=yes xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80

    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done