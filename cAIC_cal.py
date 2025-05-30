import numpy as np
from scipy.special import gamma

def calLnL(bin_cen,data_cen,mod):
    '''
    calculate the ln(likelihood) of the fitting.
    '''
    gamma_values = gamma(data_cen + 1)
    negative_indices = np.where(gamma_values < 0)[0]
    
    if len(negative_indices) > 0:
        # Remove indices with negative gamma values
        bin_cen = np.delete(bin_cen, negative_indices)
        data_cen = np.delete(data_cen, negative_indices)
        mod = np.delete(mod, negative_indices)
    
    bin_n = int(np.shape(bin_cen)[0])
    term2 = data_cen*np.log(mod)
    term3 = np.log(gamma(data_cen+1))
    tot_term = -1*mod+term2-term3
    res = np.sum(tot_term)
    return res,bin_n

def calcAIC(bin_cen,data_cen,mod,fpar_k):
    '''
    calculate the corrected AIC for given fitting
    fpar_k: number of free par
    bin_n: number of bins
    '''
    LnL,bin_n = calLnL(bin_cen,data_cen,mod)
    #LnL,bin_n = calLnL_alt(wrkdir,fname)
    term3 = (2*fpar_k**2+2*fpar_k)/(bin_n-fpar_k-1)
    cAIC = -2*LnL + 2*fpar_k + term3
    return cAIC