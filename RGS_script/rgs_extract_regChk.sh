#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="RGS Checking: generate extraction region / src / bkg"
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
    #total spatial
    evselect table=`ls *R1S*EVEN*`':EVENTS' imageset='rgs1_tot.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR'
    #banana plot
    evselect table=`ls *R1S*EVEN*`':EVENTS' imageset='rgs1_pi.fit' xcolumn='M_LAMBDA' ycolumn='PI' yimagemin=0 yimagemax=3000 expression="REGION("${src1}":RGS1_SRC3_SPATIAL,M_LAMBDA,XDSP_CORR)"
    #bkg plot
    evselect table=`ls *R1S*EVEN*`':EVENTS' imageset='rgs1_bkg.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' expression='REGION('${src1}':RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR)'
    #src plot 
    evselect table=`ls *R1S*EVEN*`':EVENTS' imageset='rgs1_src.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' expression='REGION('${src1}':RGS1_SRC3_SPATIAL,M_LAMBDA,XDSP_CORR)'

    
    #evselect table=`ls *R1S*EVEN*` timebinsize=100 rateset=rgs1_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR))"
    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done
