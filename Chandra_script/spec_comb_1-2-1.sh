#!/bin/sh
#===================================================
#tg_spec_1-1-1.sh
version=1.2.1
author="Fangzheng Shi"
copyrights="All rights reserved. 2017-2027"
manual="Please execute the script and give the following 3 parameters in sequence: 1. ADDRESS of your working directory where the src/bkg spectra and rmf/arf files reside, 2.SOURCE NAME, 3.INST(HEG/MEG) 4. order of arms"
#=========================================
cd /Volumes/Pegasus/LLAGN_archive/Mrk3/gspec
pwd
#a=pha_$2

#echo $a
#ls *ph2* > pha.lis
#ls *garf* > arf.lis
#ls *.rmf > rmf.lis

evtname="12874 12875  13254  13261  13263  13264  13406  14331"
#evtname="873  12874"

for osid in $evtname
do
  ls ${osid}*ph2_heg.fits > pha_tmp.lis
  ls ${osid}*garf* > arf_tmp.lis
  ls ${osid}*.rmf > rmf_tmp.lis
  punlearn combine_grating_spectra
  pset combine_grating_spectra infile=@pha_tmp.lis
  pset combine_grating_spectra arf=@arf_tmp.lis
  pset combine_grating_spectra rmf=@rmf_tmp.lis
  pset combine_grating_spectra garm=HEG
  pset combine_grating_spectra add_plusminus=yes
  pset combine_grating_spectra order=1
  pset combine_grating_spectra mode=h
  pset combine_grating_spectra clobber=yes
  pset combine_grating_spectra outroot=${osid}
  combine_grating_spectra
  rm pha_tmp.lis
  rm arf_tmp.lis
  rm rmf_tmp.lis

done
