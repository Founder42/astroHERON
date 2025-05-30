#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="Filter flaring particle BKG: generate gti + redo rgsproc from stage 3. Threshold count rate must be specified during execution, e.g. './rgs_extract_gtiFilt.sh 0.1'"
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
    #rgsproc withsrc=yes srclabel=M83N srcra=204.2524 srcdec=-29.866 >& cen_rgsproc_log

    src1=$(ls *R1S*SRC*)
    src2=$(ls *R2S*SRC*)

    tabgtigen table=rgs1_bkg_lc.fit gtiset=rgs1_low.fit expression='(RATE<'$1')'
    tabgtigen table=rgs2_bkg_lc.fit gtiset=rgs2_low.fit expression='(RATE<'$1')'

    rgsproc entrystage=3:filter auxgtitables='rgs1_low.fit rgs2_low.fit' >& gti_rgsproc_log
    #evselect table=`ls *R1S*EVEN*` timebinsize=100 rateset=rgs1_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR))"
    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done
