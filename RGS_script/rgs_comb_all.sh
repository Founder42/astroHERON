#!/usr/bin/env bash
#==============================================================================
# Script: rgs_comb_all.sh
# Version: 2.0.0 (Unified Industrial CLI)
# Author: Fangzheng Shi & Logos
# Description: XMM-Newton RGS Multi-Epoch Cross-Observation Spectral Combination
#              and Optimal Binning for a designated target source.
#==============================================================================

set -eo pipefail

# ---------------------------------------------------------
# Default values & color formatting
# ---------------------------------------------------------
OBS_IDS=""
IN_DIR=""
SRC_NAME=""
OUT_DIR=""

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
Usage: $(basename "$0") -o <OBS_IDS> -i <DATA_DIR> -s <SRC_NAME> [options]

Mandatory Arguments:
  -o <OBS_IDS>     Observation ID list (comma-separated list, e.g. "0084030101,0900170101")
  -i <DATA_DIR>    Root directory containing raw/processing observation data
  -s <SRC_NAME>    Target source name prefix for combined products (e.g. "NGC2617")

Optional Arguments:
  -d <OUT_DIR>     Output subdirectory under <DATA_DIR> (default: <SRC_NAME>_tot_spec)
  -h               Display this help manual and exit

Examples:
  # 1. Standard cross-epoch combination for target NGC2617
  $(basename "$0") -o "0701981601,0701981901" -i /home/shi/data/NGC2617/XMM -s NGC2617

  # 2. Combining 3 epochs for M104 with custom directory name
  $(basename "$0") -o "0084030101,0900170101,0900170201" -i /Volumes/Pegasus/LLAGN_archive/M104/XMM \\
                   -s M104 -d M104_combined_spec
EOF
    exit "${1:-0}"
}

# ---------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------
while getopts ":o:i:s:d:h" opt; do
    case "${opt}" in
        o) OBS_IDS="${OPTARG}" ;;
        i) IN_DIR="${OPTARG}" ;;
        s) SRC_NAME="${OPTARG}" ;;
        d) OUT_DIR="${OPTARG}" ;;
        h) usage 0 ;;
        \?) echo -e "${RED}[ERROR] Invalid option: -${OPTARG}${NC}" >&2; usage 1 ;;
        :)  echo -e "${RED}[ERROR] Option -${OPTARG} requires an argument.${NC}" >&2; usage 1 ;;
    esac
done

# ---------------------------------------------------------
# Defensive Sanity Checks
# ---------------------------------------------------------
if [ -z "${OBS_IDS}" ] || [ -z "${IN_DIR}" ] || [ -z "${SRC_NAME}" ]; then
    echo -e "${RED}[ERROR] Missing mandatory arguments (-o, -i, -s).${NC}" >&2
    usage 1
fi

if [ ! -d "${IN_DIR}" ]; then
    echo -e "${RED}[ERROR] Specified data root directory does not exist: '${IN_DIR}'${NC}" >&2
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

# ---------------------------------------------------------
# Parse ObsID List (Strict comma delimiter, strip spaces & NBSP)
# ---------------------------------------------------------
IFS=',' read -r -a RAW_OBS_ARRAY <<< "${OBS_IDS}"
OBS_ARRAY=()
for x in "${RAW_OBS_ARRAY[@]}"; do
    clean_id=$(printf '%s' "${x}" | tr -d '[:space:]' | sed "s/$(printf '\xc2\xa0')//g")
    [ -n "${clean_id}" ] && OBS_ARRAY+=("${clean_id}")
done

if [ "${#OBS_ARRAY[@]}" -eq 0 ]; then
    echo -e "${RED}[ERROR] No valid ObsIDs provided in -o list.${NC}" >&2
    exit 1
fi

# ---------------------------------------------------------
# Setup Target Combination Directory
# ---------------------------------------------------------
OUT_DIR="${OUT_DIR:-${SRC_NAME}_tot_spec}"
TARGET_DIR="${IN_DIR}/${OUT_DIR}"

if [ ! -d "${TARGET_DIR}" ]; then
    echo -e "${GREEN}[INFO] Creating combination directory: ${TARGET_DIR}${NC}"
    mkdir -p "${TARGET_DIR}"
else
    echo -e "${GREEN}[INFO] Reusing existing combination directory: ${TARGET_DIR}${NC}"
fi

# ---------------------------------------------------------
# Ingest Spectrum Products across all ObsIDs
# ---------------------------------------------------------
ALL_SRC_FILES=()
ALL_BKG_FILES=()
ALL_MAT_FILES=()
FOUND_U=false

for obsid in "${OBS_ARRAY[@]}"; do
    echo -e "\n${BLUE}--> Locating spectrum products for ObsID: ${obsid}${NC}"

    # Locate ObsID folder
    if [ -d "${IN_DIR}/${obsid}" ]; then
        SRC_DIR="${IN_DIR}/${obsid}"
    elif [ -d "${IN_DIR}" ] && [[ "$(basename "${IN_DIR}")" == "${obsid}" ]]; then
        SRC_DIR="${IN_DIR}"
    else
        echo -e "${RED}[ERROR] Could not locate directory for ObsID '${obsid}' under '${IN_DIR}'.${NC}" >&2
        exit 1
    fi

    # Search for Order 1 files (*1003*) in root of ObsID directory
    fsrc_arr=($(ls "${SRC_DIR}"/*R*S*SRSPEC1003* 2>/dev/null || true))
    fbkg_arr=($(ls "${SRC_DIR}"/*R*S*BGSPEC1003* 2>/dev/null || true))
    fmat_arr=($(ls "${SRC_DIR}"/*R*S*RSPMAT1003* 2>/dev/null || true))

    # Fallback to Unscheduled 'U' in root if 'S' absent
    if [ "${#fsrc_arr[@]}" -eq 0 ]; then
        fsrc_arr=($(ls "${SRC_DIR}"/*R*U*SRSPEC1003* 2>/dev/null || true))
        fbkg_arr=($(ls "${SRC_DIR}"/*R*U*BGSPEC1003* 2>/dev/null || true))
        fmat_arr=($(ls "${SRC_DIR}"/*R*U*RSPMAT1003* 2>/dev/null || true))
        [ "${#fsrc_arr[@]}" -gt 0 ] && FOUND_U=true
    fi

    # Fallback to ${obsid}_spec subfolder if files were organized by rgs_comb_epoch.sh
    if [ "${#fsrc_arr[@]}" -eq 0 ] && [ -d "${SRC_DIR}/${obsid}_spec" ]; then
        echo -e "${YELLOW}[INFO] Searching in subfolder: ${SRC_DIR}/${obsid}_spec/${NC}"
        fsrc_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*S*SRSPEC1003* 2>/dev/null || true))
        fbkg_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*S*BGSPEC1003* 2>/dev/null || true))
        fmat_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*S*RSPMAT1003* 2>/dev/null || true))
        if [ "${#fsrc_arr[@]}" -eq 0 ]; then
            fsrc_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*U*SRSPEC1003* 2>/dev/null || true))
            fbkg_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*U*BGSPEC1003* 2>/dev/null || true))
            fmat_arr=($(ls "${SRC_DIR}/${obsid}_spec"/*R*U*RSPMAT1003* 2>/dev/null || true))
            [ "${#fsrc_arr[@]}" -gt 0 ] && FOUND_U=true
        fi
    fi

    if [ "${#fsrc_arr[@]}" -eq 0 ]; then
        echo -e "${RED}[ERROR] No 1st-order source spectra (*SRSPEC1003*) found for ObsID '${obsid}'.${NC}" >&2
        echo -e "${RED}Please verify that Step 1 and Step 2 extraction completed successfully for this ObsID.${NC}" >&2
        exit 1
    fi

    if [ "${#fsrc_arr[@]}" -ne "${#fbkg_arr[@]}" ] || [ "${#fsrc_arr[@]}" -ne "${#fmat_arr[@]}" ]; then
        echo -e "${RED}[ERROR] Mismatched counts between spectral components for ObsID '${obsid}':${NC}" >&2
        echo "  Source spectra (SRSPEC) : ${#fsrc_arr[@]} files (${fsrc_arr[*]})" >&2
        echo "  Bkg spectra (BGSPEC)    : ${#fbkg_arr[@]} files (${fbkg_arr[*]})" >&2
        echo "  Responses (RSPMAT)      : ${#fmat_arr[@]} files (${fmat_arr[*]})" >&2
        exit 1
    fi

    echo -e "${GREEN}[INFO] Found ${#fsrc_arr[@]} spectral component(s) for ObsID ${obsid}. Ingesting into ${TARGET_DIR}/...${NC}"
    cp -p "${fsrc_arr[@]}" "${fbkg_arr[@]}" "${fmat_arr[@]}" "${TARGET_DIR}/"

    for f in "${fsrc_arr[@]}"; do ALL_SRC_FILES+=("$(basename "${f}")"); done
    for f in "${fbkg_arr[@]}"; do ALL_BKG_FILES+=("$(basename "${f}")"); done
    for f in "${fmat_arr[@]}"; do ALL_MAT_FILES+=("$(basename "${f}")"); done
done

if [ "${#ALL_SRC_FILES[@]}" -eq 0 ]; then
    echo -e "${RED}[ERROR] No spectral files were collected across all specified ObsIDs.${NC}" >&2
    exit 1
fi

# ---------------------------------------------------------
# Spectral Combination & Rebinning
# ---------------------------------------------------------
cd "${TARGET_DIR}"

echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Starting Multi-Epoch Combination for Target: ${SRC_NAME}${NC}"
echo -e "${BLUE}  Total Spectra to Combine: ${#ALL_SRC_FILES[@]}${NC}"
echo -e "${BLUE}=================================================================${NC}"

filepha="${SRC_NAME}_o1_src.fits"
filermf="${SRC_NAME}_o1.rmf"
filebkg="${SRC_NAME}_o1_bkg.fits"
outfile="${SRC_NAME}_o1_opt.grp"

fsrc_str="${ALL_SRC_FILES[*]}"
fbkg_str="${ALL_BKG_FILES[*]}"
fmat_str="${ALL_MAT_FILES[*]}"

echo "Source spectra : ${fsrc_str}"
echo "Bkg spectra    : ${fbkg_str}"
echo "Response files : ${fmat_str}"

# 1. Combine across epochs with SAS rgscombine
echo -e "\n${GREEN}[INFO] Stacking spectra using SAS rgscombine...${NC}"
rgscombine pha="${fsrc_str}" rmf="${fmat_str}" bkg="${fbkg_str}" \
           filepha="${filepha}" filermf="${filermf}" filebkg="${filebkg}"

# 2. Optimal Grouping with HEASOFT ftgrouppha
echo -e "${GREEN}[INFO] Rebinning combined spectrum with ftgrouppha (optimal binning)...${NC}"
ftgrouppha infile="${filepha}" backfile="${filebkg}" outfile="${outfile}" \
           grouptype=opt respfile="${filermf}" clobber=yes

# ---------------------------------------------------------
# Notifications & Inspection Guidance
# ---------------------------------------------------------
if [ "${FOUND_U}" = true ]; then
    echo -e "\n${YELLOW}[WARNING] Unscheduled ('U') exposure spectra were included in this combination.${NC}"
fi

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Multi-Epoch Combination Completed for Source: ${SRC_NAME}${NC}"
echo -e "${GREEN}  All products organized in: ${TARGET_DIR}/${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo "Combined Files:"
echo "  - Source spectrum : ${filepha}"
echo "  - Response matrix : ${filermf}"
echo "  - Bkg spectrum    : ${filebkg}"
echo "  - Grouped spectrum: ${outfile}"
echo ""
echo "To inspect or fit in XSPEC, execute:"
echo "  cd \"${TARGET_DIR}\" && xspec"
echo "  XSPEC12> data 1:1 ${outfile}"