#!/bin/sh
#===================================================
#spec_extract_0order.sh
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2021-2031"
update=""
manual="RGS reprocessing: combine spec and to rebin for each epoch. Before this u should use evselect manually check the threshold"
#=========================================
#obsid=("0110910201")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    #export SAS_CCF=`pwd`/ccf.cif
    #export SAS_ODF=`pwd`/`ls *SUM.SAS`
    #rgsproc withsrc=yes srclabel=M83N srcra=204.2524 srcdec=-29.866 >& cen_rgsproc_log

    fsrc=$(ls *R*S*SRSPEC1003* | tr '\n' ' ')
    fbkg=$(ls *R*S*BGSPEC1003* | tr '\n' ' ')
    fmat=$(ls *R*S*RSPMAT1003* | tr '\n' ' ')

    #rgscombine pha="${fsrc% }" rmf="${fmat% }" bkg="${fbkg% }" filepha=$x"_o1_src.fits" filermf=$x"_o1.rmf" filebkg=$x"_o1_bkg.fits"
    #ftgrouppha infile=$x"_o1_src.fits" backfile=$x"_o1_bkg.fits" outfile=$x"_o1_opt.grp" grouptype=opt respfile=$x"_o1.rmf" clobber=yes

    rgscombine pha="${fsrc% }" rmf="${fmat% }" bkg="${fbkg% }" filepha=$x"_o1_try2_src.fits" filermf=$x"_o1_try2.rmf" filebkg=$x"_o1_try2_bkg.fits"
    ftgrouppha infile=$x"_o1_try2_src.fits" backfile=$x"_o1_try2_bkg.fits" outfile=$x"_o1_try2_opt.grp" grouptype=opt respfile=$x"_o1_try2.rmf" clobber=yes

    #evselect table=`ls *R1S*EVEN*` timebinsize=100 rateset=rgs1_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR))"
    #evselect table=`ls *R2S*EVEN*` timebinsize=100 rateset=rgs2_bkg_lc.fit makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src2}":RGS2_BACKGROUND,M_LAMBDA,XDSP_CORR))"
done