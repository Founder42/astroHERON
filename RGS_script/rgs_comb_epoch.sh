#!/usr/bin/env bash
#==============================================================================
# Script: rgs_comb_epoch.sh
# Version: 2.0.0 (Unified Industrial CLI)
# Author: Fangzheng Shi & Logos
# Description: XMM-Newton RGS Module Spectral Combination & Optimal Binning
#==============================================================================

set -eo pipefail

# ---------------------------------------------------------
# Default values & color formatting
# ---------------------------------------------------------
OBS_IDS=""
IN_DIR=""
CCF_PATH="${SAS_CCFPATH:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---------------------------------------------------------
# Usage Documentation
# ---------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") -o <OBSID> -i <DATA_DIR> [options]

Mandatory Arguments:
  -o <OBSID>       Observation ID (single ID or quoted list, e.g. "0084030101 0900170101")
  -i <DATA_DIR>    Root directory containing raw/processing ODF observation data

Optional Arguments:
  -c <CCF_PATH>    Path to SAS CCF calibration directory (default: \$SAS_CCFPATH)
  -h               Display this help manual and exit

Examples:
  # 1. Standard execution for single ObsID
  $(basename "$0") -o 0084030101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM

  # 2. Specifying explicit CCF directory
  $(basename "$0") -o 0900170101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM \\
                   -c /Users/fangzheng42/Program/SAS/ccf

  # 3. Batch processing multiple ObsIDs
  $(basename "$0") -o "0084030101 0900170101" -i /Volumes/Pegasus/LLAGN_archive/M104/XMM
EOF
    exit "${1:-0}"
}

# ---------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------
while getopts ":o:i:c:h" opt; do
    case "${opt}" in
        o) OBS_IDS="${OPTARG}" ;;
        i) IN_DIR="${OPTARG}" ;;
        c) CCF_PATH="${OPTARG}" ;;
        h) usage 0 ;;
        \?) echo -e "${RED}[ERROR] Invalid option: -${OPTARG}${NC}" >&2; usage 1 ;;
        :)  echo -e "${RED}[ERROR] Option -${OPTARG} requires an argument.${NC}" >&2; usage 1 ;;
    esac
done

# ---------------------------------------------------------
# Defensive Sanity Checks
# ---------------------------------------------------------
if [ -z "${OBS_IDS}" ] || [ -z "${IN_DIR}" ]; then
    echo -e "${RED}[ERROR] Missing mandatory arguments (-o, -i).${NC}" >&2
    usage 1
fi

if [ ! -d "${IN_DIR}" ]; then
    echo -e "${RED}[ERROR] Specified data root directory does not exist: '${IN_DIR}'${NC}" >&2
    exit 1
fi

if [ -n "${CCF_PATH}" ] && [ ! -d "${CCF_PATH}" ]; then
    echo -e "${RED}[ERROR] SAS CCF calibration directory is invalid: '${CCF_PATH}'${NC}" >&2
    exit 1
fi

# Verify tool dependencies exist in PATH
if ! command -v rgscombine >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] SAS tool 'rgscombine' not found in PATH. Please initialize SAS environment before running.${NC}" >&2
    exit 1
fi

if ! command -v ftgrouppha >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] HEASOFT tool 'ftgrouppha' not found in PATH. Please initialize HEASOFT environment before running.${NC}" >&2
    exit 1
fi

[ -n "${CCF_PATH}" ] && export SAS_CCFPATH="${CCF_PATH}"

# ---------------------------------------------------------
# Process ObsID(s)
# ---------------------------------------------------------
IFS=', ' read -r -a OBS_ARRAY <<< "${OBS_IDS}"

for obsid in "${OBS_ARRAY[@]}"; do
    [ -n "${obsid}" ] || continue
    echo -e "\n${BLUE}=================================================================${NC}"
    echo -e "${BLUE}  Starting RGS Module Combination for ObsID: ${obsid}${NC}"
    echo -e "${BLUE}=================================================================${NC}"

    # Locate Target Data Directory
    if [ -d "${IN_DIR}/${obsid}" ]; then
        WORK_DIR="${IN_DIR}/${obsid}"
    elif [ -d "${IN_DIR}" ] && [[ "$(basename "${IN_DIR}")" == "${obsid}" ]]; then
        WORK_DIR="${IN_DIR}"
    else
        echo -e "${RED}[ERROR] Could not locate directory for ObsID '${obsid}' under '${IN_DIR}'.${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}[INFO] Working Directory  : ${WORK_DIR}${NC}"
    cd "${WORK_DIR}"

    # Optional calibration environment assignment if present
    if [ -f "ccf.cif" ]; then
        export SAS_CCF="$(pwd)/ccf.cif"
    fi
    SUM_FILE="$(ls *SUM.SAS 2>/dev/null | head -n 1 || true)"
    if [ -n "${SUM_FILE}" ]; then
        export SAS_ODF="$(pwd)/${SUM_FILE}"
    fi

    # 1. Detect 1st-order spectra (order 1, custom centroid SRC3 -> 1003)
    echo -e "${GREEN}[INFO] Searching for Order 1 spectrum products (*1003*)...${NC}"
    fsrc_arr=($(ls *R*S*SRSPEC1003* 2>/dev/null || true))
    fbkg_arr=($(ls *R*S*BGSPEC1003* 2>/dev/null || true))
    fmat_arr=($(ls *R*S*RSPMAT1003* 2>/dev/null || true))
    FOUND_U=false

    # Fallback to Unscheduled 'U' spectra if Scheduled 'S' is absent
    if [ "${#fsrc_arr[@]}" -eq 0 ]; then
        fsrc_arr=($(ls *R*U*SRSPEC1003* 2>/dev/null || true))
        fbkg_arr=($(ls *R*U*BGSPEC1003* 2>/dev/null || true))
        fmat_arr=($(ls *R*U*RSPMAT1003* 2>/dev/null || true))
        if [ "${#fsrc_arr[@]}" -gt 0 ]; then
            FOUND_U=true
        fi
    fi

    if [ "${#fsrc_arr[@]}" -eq 0 ]; then
        echo -e "${RED}[ERROR] No 1st-order source spectra (*SRSPEC1003*) found in $(pwd).${NC}" >&2
        echo -e "${RED}Please verify that previous extraction steps completed successfully.${NC}" >&2
        exit 1
    fi

    if [ "${#fsrc_arr[@]}" -ne "${#fbkg_arr[@]}" ] || [ "${#fsrc_arr[@]}" -ne "${#fmat_arr[@]}" ]; then
        echo -e "${RED}[ERROR] Mismatched counts between spectral components in $(pwd):${NC}" >&2
        echo "  Source spectra (SRSPEC) : ${#fsrc_arr[@]} files (${fsrc_arr[*]})" >&2
        echo "  Bkg spectra (BGSPEC)    : ${#fbkg_arr[@]} files (${fbkg_arr[*]})" >&2
        echo "  Responses (RSPMAT)      : ${#fmat_arr[@]} files (${fmat_arr[*]})" >&2
        exit 1
    fi

    fsrc_str="${fsrc_arr[*]}"
    fbkg_str="${fbkg_arr[*]}"
    fmat_str="${fmat_arr[*]}"

    echo "Source spectra : ${fsrc_str}"
    echo "Bkg spectra    : ${fbkg_str}"
    echo "Response files : ${fmat_str}"

    # 2. Output File Names
    filepha="${obsid}_o1_src.fits"
    filermf="${obsid}_o1.rmf"
    filebkg="${obsid}_o1_bkg.fits"
    outfile="${obsid}_o1_opt.grp"

    # 3. Spectral Combination (rgscombine)
    echo -e "${GREEN}[INFO] Combining spectra across modules using rgscombine...${NC}"
    rgscombine pha="${fsrc_str}" rmf="${fmat_str}" bkg="${fbkg_str}" \
               filepha="${filepha}" filermf="${filermf}" filebkg="${filebkg}"

    # 4. Optimal Binning (ftgrouppha)
    echo -e "${GREEN}[INFO] Rebinning combined spectrum with ftgrouppha (optimal binning)...${NC}"
    ftgrouppha infile="${filepha}" backfile="${filebkg}" outfile="${outfile}" \
               grouptype=opt respfile="${filermf}" clobber=yes

    # 5. Product Archival into {ObsID}_spec/ folder
    spec_dir="${obsid}_spec"
    echo -e "${GREEN}[INFO] Organizing spectra into subfolder: ${spec_dir}/...${NC}"
    mkdir -p "${spec_dir}"

    echo "Copying individual module files..."
    cp -p "${fsrc_arr[@]}" "${fbkg_arr[@]}" "${fmat_arr[@]}" "${spec_dir}/"

    echo "Moving combined and grouped products..."
    mv "${filepha}" "${filermf}" "${filebkg}" "${outfile}" "${spec_dir}/"

    # 6. Notifications & Guidance
    if [ "${FOUND_U}" = true ]; then
        echo -e "\n${YELLOW}[WARNING] Unscheduled ('U') exposure spectra were combined in this observation.${NC}"
    fi

    echo -e "\n${GREEN}=================================================================${NC}"
    echo -e "${GREEN}  Combination & Optimal Grouping Completed for ObsID: ${obsid}${NC}"
    echo -e "${GREEN}  All products organized in: ${WORK_DIR}/${spec_dir}${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    echo "Combined Files:"
    echo "  - Source spectrum : ${filepha}"
    echo "  - Response matrix : ${filermf}"
    echo "  - Bkg spectrum    : ${filebkg}"
    echo "  - Grouped spectrum: ${outfile}"
    echo ""
    echo "To inspect or fit in XSPEC, execute:"
    echo "  cd \"${WORK_DIR}/${spec_dir}\" && xspec"
    echo "  XSPEC12> data 1:1 ${outfile}"
done