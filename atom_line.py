import numpy as np
from astropy.io import fits
import os

def kT_sample(atomdb_path):
    """
    Extract temperature sampling points from an AtomDB FITS file.
    
    Parameters:
    -----------
    atomdb_path : str
        Path to the AtomDB FITS file
        
    Returns:
    --------
    numpy.ndarray
        1D array of temperature values from the 'kT' column
    """
    # Verify the file exists
    if not os.path.isfile(atomdb_path):
        raise FileNotFoundError(f"The file {atomdb_path} does not exist.")
    
    # Open the FITS file
    try:
        with fits.open(atomdb_path) as hdul:
            # Access the 'PARAMETERS' extension (index 1)
            parameters_table = hdul[1].data
            
            # Verify this is the 'PARAMETERS' extension
            if hdul[1].name != 'PARAMETERS':
                raise ValueError(f"Extension at index 1 is named '{hdul[1].name}', expected 'PARAMETERS'.")
            
            # Verify the 'kT' column exists
            if 'kT' not in parameters_table.names:
                raise ValueError(f"Column 'kT' not found in the PARAMETERS extension.")
            
            # Extract the 'kT' column and ensure it's a float array
            kt_values = np.array(parameters_table['kT'], dtype=float)
            
        return kt_values[1:-1] # Exclude the first and last values
    
    except Exception as e:
        raise RuntimeError(f"Error reading FITS file: {str(e)}")
