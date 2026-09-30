# astroHERON

- Stands for **"ASTROphysical High-EneRgy data reduction: OpeN-source code"**
- This is a collection of useful codes and scripts for data reduction, spectral and image analysis for high-energy astrophysics (especially for X-ray astronomy).
- The name comes after one of the author's favorite birds: Black-crowned Night Heron (*Nycticorax nycticorax*), very popular in either cities or countryside in China, also known as the "Chinese Rural Penguin" (because it has a similar color pattern and posture).

---

## Modules & Pipeline Overview

### 1. XMM-Newton RGS Pipeline (`RGS_script/`)

Modernized, industrial-grade Bash CLI pipelines based on ESA's **Science Analysis System (SAS)** and NASA's **HEASOFT**. All scripts support standardized command-line flags (`getopts`), robust input validation, Zero Semantic Drift on scientific algorithms, and seamless handling of both Scheduled (`S`) and Unscheduled (`U`) exposures.

#### Step 1: Calibration, Reprocessing & Flare Light Curve (`rgs_extract_step1.sh`)
- Automated in-situ ODF decompression (`.gz`, `.TAR`/`.tar`).
- Intelligent calibration ingestion (`cifbuild` for `ccf.cif`, `odfingest` for `*SUM.SAS`).
- Pipeline reduction with forced extraction centroid (`rgsproc withsrc=yes srclabel=... srcra=... srcdec=...`).
- Flare background light curve extraction (`evselect` on CCDNR=9) for RGS1 and RGS2.
- Guidance commands for inspecting flare thresholds via `dsplot`.

```bash
# Example:
./RGS_script/rgs_extract_step1.sh -o <OBSID> -i <DATA_DIR> -r <RA> -d <DEC> [-s <SRC_NAME>] [-c <CCF_PATH>]
```

#### Step 2: Flaring GTI Filtering & Region Diagnostics (`rgs_extract_step2_gtiFilt_regChk.sh`)
- Generates Good Time Interval (GTI) filter tables using `tabgtigen` based on user threshold count rate.
- Re-runs `rgsproc` starting from Stage 3 (`entrystage=3:filter`) with auxiliary GTI tables.
- Extracts 4 diagnostic spatial/energy imagesets on module R1 (`rgs1_tot.fit`, `rgs1_pi.fit`, `rgs1_bkg.fit`, `rgs1_src.fit`) referencing custom source centroid (`SRC3`).
- Outputs interactive `rgsimplot` inspection commands.

```bash
# Example:
./RGS_script/rgs_extract_step2_gtiFilt_regChk.sh -o <OBSID> -i <DATA_DIR> -t <THRESHOLD> [-c <CCF_PATH>]
```

#### Step 3: Module Spectral Combination & Optimal Binning (`rgs_comb_epoch.sh`)
- Combines 1st-order (`1003`) spectra across RGS1 and RGS2 modules using SAS `rgscombine`.
- Optimally groups the combined spectrum using HEASOFT `ftgrouppha` (`grouptype=opt`).
- Automatically creates `${OBSID}_spec/`, backing up individual module spectra and organizing combined/grouped spectra ready for XSPEC fitting (`data 1:1 <OBSID>_o1_opt.grp`).

```bash
# Example:
./RGS_script/rgs_comb_epoch.sh -o <OBSID> -i <DATA_DIR> [-c <CCF_PATH>]
```

---

### 2. XMM-Newton EPIC (`EPIC_script/`)
*Under construction.*

---

### 3. Chandra CIAO (`Chandra_script/`)
*Under construction.*

---

### 4. Ancillary Astrophysics Tools
- `atom_line.py`: Atomic emission line reference tool.
- `cAIC_cal.py`: Corrected Akaike Information Criterion (cAIC) calculator for model selection.
- *Other tools*: Under construction.
