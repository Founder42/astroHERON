import .....

def genXspecMod1D(tmpfile, modname , parname, parInit, parDel, parMin, parBot, parTop, parMax, parVal, ebin_lo, ebin_hi, spec_pack, outfile):
    '''
    generate the additive table model file with 1 free parameters in fits format for Xspec
    **********
    Todo:
    - [ ] *The function is ugly! Change to class please!*
    - [ ] unit of free par
    *******
    INPUT:
    - tmpfile: path and filename to tmp model file
    - modname: string of your model name (better less than 8 characters), e.g.: 'SoftHW','M83BKG'
    - parname: array of string of your parname, e.g.: ['incli'], ['scale']
    - parInit, parDel, parMin,parBot, parTop, parMax: array of initial/delta/min/bottom/top/max value of par
    - parVal: array of free par value
    - ebin_lo, ebin_hi: ebin must be the original ebin left and right edge
    - spec_pack: array of all spec for each free par value, unit of model spec: cts/s/cm2 <-- **ATTENTION! MUST BE INTEGRAL FLUX**
    - outfile: output fits file name
    *******
    OUTPUT:
    - model fits file
    '''
    #spec_pack = [ ]
    #spec_pack = np.array(spec_pack)
    
    addr = tmpfile
    with fits.open(addr) as hdu_list_tmp:
        hd_pri = hdu_list_tmp[0].header
        hd_pri['MODLNAME'] = modname
        hd_par = hdu_list_tmp[1].header
        hd_par['NAXIS2'] = 1
        hd_par['TFORM10'] = '2E'
        hd_par['NADDPARM'] = 0
        hd_par['NINTPARM'] = 1
        da_par = hdu_list_tmp[1].data
        da_par['NAME'] = parname
        da_par['INITIAL'] = parInit
        da_par['DELTA'] = parDel
        da_par['MINIMUM'] = parMin
        da_par['BOTTOM'] = parBot
        da_par['TOP'] = parTop
        da_par['MAXIMUM'] = parMax
        da_par['NUMBVALS'] = int(np.shape(np.array(parVal))[0])
        da_par['VALUE'] = np.array(parVal)
        da_par['UNITS'] = b' '

        hd_ene = hdu_list_tmp[2].header
        hd_ene['NAXIS2'] = int(np.shape(ebin_lo)[0])
        da_ene = hdu_list_tmp[2].data
        da_ene['ENERG_LO'] = ebin_lo
        da_ene['ENERG_HI'] = ebin_hi

        hd_spe = hdu_list_tmp[3].header
        hd_spe['NAXIS2'] = int(np.shape(np.array(parVal))[0])
        hd_spe['TFORM1'] = '1E'
        hd_spe['TFORM2'] = str(int(np.shape(ebin_lo)[0]))+'E'
        da_spe = hdu_list_tmp[3].data
        da_spe['PARAMVAL'] = np.array(parVal)
        da_spe['INTPSPEC'] = spec_pack


    new_hdu0 = fits.PrimaryHDU(header = hd_pri)
    new_hdu1 = fits.BinTableHDU(data = da_par, header = hd_par)
    new_hdu2 = fits.BinTableHDU(data = da_ene, header = hd_ene)
    new_hdu3 = fits.BinTableHDU(data = da_spe, header =hd_spe)
    new_hdu_tot = fits.HDUList([new_hdu0, new_hdu1, new_hdu2, new_hdu3])
    new_hdu_tot.writeto(outfile, overwrite = True)

    return None