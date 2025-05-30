#!/bin/sh
#===================================================
#tg_spec_1-0-1.sh
version=1.2.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
manual="Combine PHA type spec. Please execute the script and give the following 1 parameters in sequence: 1. suffix of your spec. 2.outroot name"
#===============================================

#cd $1

#ls *ph2* > pha.lis
#ls *garf* > arf.lis
#ls *.rmf > rmf.lis


#for osid in $evtname
#do
  dir=/Users/fangzheng42/Documents/HUBS/M104/combine_spec/ACIS-S_spec
  cd ${dir}
  rm -f pha_$1.lis bkg_$1.lis rmf_$1.lis arf_$1.lis
  ls *$1.pi > pha_$1.lis
  ls *bkg.pi > bkg_$1.lis
  ls *.rmf > rmf_$1.lis
  ls *.arf > arf_$1.lis
  punlearn combine_spectra
  pset combine_spectra src_spectra=@pha_$1.lis
  pset combine_spectra src_arfs=@arf_$1.lis
  pset combine_spectra src_rmfs=@rmf_$1.lis
  #pset combine_grating_spectra garm=HEG
  pset combine_spectra bkg_spectra=@bkg_$1.lis
  pset combine_spectra mode=h
  pset combine_spectra clobber=yes
  pset combine_spectra outroot=$2"_"$1
  combine_spectra

#done
