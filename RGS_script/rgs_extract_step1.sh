#!/usr/bin/env bash
#==============================================================================
# Script: rgs_extract_step1.sh
# Version: 2.0.0 (Unified Industrial CLI)
# Author: Fangzheng Shi & Logos
# Description: XMM-Newton RGS Pipeline Step 1 - Calibration, Reprocessing & Flare LC Check
#==============================================================================

set -eo pipefail

# ---------------------------------------------------------
# Default values & color formatting
# ---------------------------------------------------------
OBS_IDS=""
IN_DIR=""
SRC_NAME=""
SRC_RA=""
SRC_DEC=""
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
Usage: $(basename "$0") -o <OBSID> -i <DATA_DIR> -r <RA> -d <DEC> [options]

Mandatory Arguments:
  -o <OBSID>       Observation ID (single ID or quoted list, e.g. "0084030101 0900170101")
  -i <DATA_DIR>    Root directory containing raw ODF observation data
  -r <RA>          Target Right Ascension in decimal degrees (J2000, 0 <= RA <= 360)
  -d <DEC>         Target Declination in decimal degrees (J2000, -90 <= DEC <= 90)

Optional Arguments:
  -s <SRC_NAME>    Target source label for rgsproc (default: same as OBSID)
  -c <CCF_PATH>    Path to SAS CCF calibration directory (default: \$SAS_CCFPATH)
  -h               Display this help manual and exit

Examples:
  # 1. Standard execution with explicit coordinates
  $(basename "$0") -o 0084030101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM -r 189.997458 -d -11.623056

  # 2. Custom source label and explicit CCF directory
  $(basename "$0") -o 0900170101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM \\
                   -s M104N -r 189.997458 -d -11.623056 \\
                   -c /Users/fangzheng42/Program/SAS/ccf

  # 3. Batch processing multiple ObsIDs with same extraction centroid
  $(basename "$0") -o "0084030101 0900170101" -i /Volumes/Pegasus/LLAGN_archive/M104/XMM \\
                   -s M104N -r 189.997458 -d -11.623056
EOF
    exit "${1:-0}"
}

# ---------------------------------------------------------
# Helper: Float validation
# ---------------------------------------------------------
is_numeric() {
    [[ "$1" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]
}

# ---------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------
while getopts ":o:i:r:d:s:c:h" opt; do
    case "${opt}" in
        o) OBS_IDS="${OPTARG}" ;;
        i) IN_DIR="${OPTARG}" ;;
        r) SRC_RA="${OPTARG}" ;;
        d) SRC_DEC="${OPTARG}" ;;
        s) SRC_NAME="${OPTARG}" ;;
        c) CCF_PATH="${OPTARG}" ;;
        h) usage 0 ;;
        \?) echo -e "${RED}[ERROR] Invalid option: -${OPTARG}${NC}" >&2; usage 1 ;;
        :)  echo -e "${RED}[ERROR] Option -${OPTARG} requires an argument.${NC}" >&2; usage 1 ;;
    esac
done

# ---------------------------------------------------------
# Defensive Sanity Checks
# ---------------------------------------------------------
if [ -z "${OBS_IDS}" ] || [ -z "${IN_DIR}" ] || [ -z "${SRC_RA}" ] || [ -z "${SRC_DEC}" ]; then
    echo -e "${RED}[ERROR] Missing mandatory arguments (-o, -i, -r, -d).${NC}" >&2
    usage 1
fi

if [ ! -d "${IN_DIR}" ]; then
    echo -e "${RED}[ERROR] Specified data root directory does not exist: '${IN_DIR}'${NC}" >&2
    exit 1
fi

if ! is_numeric "${SRC_RA}"; then
    echo -e "${RED}[ERROR] Target RA must be a valid number: '${SRC_RA}'${NC}" >&2
    exit 1
fi

if ! is_numeric "${SRC_DEC}"; then
    echo -e "${RED}[ERROR] Target DEC must be a valid number: '${SRC_DEC}'${NC}" >&2
    exit 1
fi

if [ -z "${CCF_PATH}" ] || [ ! -d "${CCF_PATH}" ]; then
    echo -e "${RED}[ERROR] SAS CCF calibration directory is invalid or not set: '${CCF_PATH}'. Specify via -c or export SAS_CCFPATH.${NC}" >&2
    exit 1
fi

# Verify SAS tools exist in PATH
for tool in cifbuild odfingest rgsproc evselect; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo -e "${RED}[ERROR] SAS tool '${tool}' not found in PATH. Please initialize SAS environment before running.${NC}" >&2
        exit 1
    fi
done

export SAS_CCFPATH="${CCF_PATH}"

# ---------------------------------------------------------
# Process ObsID(s)
# ---------------------------------------------------------
IFS=', ' read -r -a OBS_ARRAY <<< "${OBS_IDS}"

for obsid in "${OBS_ARRAY[@]}"; do
    [ -n "${obsid}" ] || continue
    echo -e "\n${BLUE}=================================================================${NC}"
    echo -e "${BLUE}  Starting RGS Step 1 Processing for ObsID: ${obsid}${NC}"
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

    CURRENT_SRC_LABEL="${SRC_NAME:-${obsid}}"

    echo -e "${GREEN}[INFO] Working Directory  : ${WORK_DIR}${NC}"
    echo -e "${GREEN}[INFO] Source Label       : ${CURRENT_SRC_LABEL}${NC}"
    echo -e "${GREEN}[INFO] Coordinates (RA,Dec): (${SRC_RA}, ${SRC_DEC})${NC}"
    echo -e "${GREEN}[INFO] SAS CCF Path       : ${SAS_CCFPATH}${NC}"

    cd "${WORK_DIR}"

    # 0. Helper: Relocate files from 'odf' subfolder if present
    flatten_odf_dir() {
        if [ -d "odf" ]; then
            echo -e "${GREEN}[INFO] Detected 'odf' subfolder in $(pwd). Moving ODF files to working root...${NC}"
            if compgen -G "odf/*" > /dev/null; then
                mv odf/* .
            fi
            rmdir odf 2>/dev/null || rm -rf odf
            echo -e "${GREEN}[INFO] Successfully relocated ODF files and removed 'odf' folder.${NC}"
        fi
    }

    # Check for pre-existing 'odf' directory
    flatten_odf_dir

    # 1. Decompression (.zip, .gz, then .TAR/.tar)
    echo -e "${GREEN}[INFO] Checking for compressed archives...${NC}"
    for zip_file in *.zip *.ZIP; do
        if [ -f "${zip_file}" ]; then
            echo "Decompressing ${zip_file}..."
            unzip -q -o "${zip_file}" || true
        fi
    done

    for gz_file in *.gz; do
        if [ -f "${gz_file}" ]; then
            echo "Decompressing ${gz_file}..."
            tar -zxvf "${gz_file}" 2>/dev/null || gunzip -f "${gz_file}" || true
        fi
    done

    for tar_file in *.TAR *.tar; do
        if [ -f "${tar_file}" ]; then
            echo "Decompressing ${tar_file}..."
            tar -xvf "${tar_file}" || true
        fi
    done

    # Check again in case decompression extracted an 'odf' folder
    flatten_odf_dir

    # 2. Calibration & Ingestion (ccf.cif & *SUM.SAS)
    echo -e "${GREEN}[INFO] Setting up Calibration and ODF Summary...${NC}"
    if [ ! -f "ccf.cif" ]; then
        echo "Generating ccf.cif via cifbuild..."
        export SAS_ODF="$(pwd)"
        cifbuild
    fi
    export SAS_CCF="$(pwd)/ccf.cif"

    if ! ls *SUM.SAS >/dev/null 2>&1; then
        echo "Generating ODF summary via odfingest..."
        export SAS_ODF="$(pwd)"
        odfingest
    fi

    SUM_FILE="$(ls *SUM.SAS 2>/dev/null | head -n 1)"
    if [ -z "${SUM_FILE}" ]; then
        echo -e "${RED}[ERROR] Failed to locate *SUM.SAS file in $(pwd).${NC}" >&2
        exit 1
    fi
    export SAS_ODF="$(pwd)/${SUM_FILE}"
    echo -e "${GREEN}[INFO] SAS_CCF set to: ${SAS_CCF}${NC}"
    echo -e "${GREEN}[INFO] SAS_ODF set to: ${SAS_ODF}${NC}"

    # 3. Pipeline Reprocessing (rgsproc with custom centroid)
    echo -e "${GREEN}[INFO] Running rgsproc with custom centroid (Log: cen_rgsproc_log)...${NC}"
    rgsproc withsrc=yes srclabel="${CURRENT_SRC_LABEL}" srcra="${SRC_RA}" srcdec="${SRC_DEC}" > cen_rgsproc_log 2>&1

    # 4. Flare Background Light Curve Extraction (evselect)
    echo -e "${GREEN}[INFO] Extracting flaring particle background light curves...${NC}"
    GEN_LCS=()
    FOUND_U_EVENTS=false

    # Check for standard scheduled 'S' event files
    for inst in 1 2; do
        src_file="$(ls *R${inst}S*SRC* 2>/dev/null | head -n 1 || true)"
        table_file="$(ls *R${inst}S*EVEN* 2>/dev/null | head -n 1 || true)"
        if [ -n "${src_file}" ] && [ -n "${table_file}" ]; then
            rateset="rgs${inst}_bkg_lc.fit"
            echo "Processing RGS${inst} Scheduled event: ${table_file} -> ${rateset}"
            evselect table="${table_file}" timebinsize=100 rateset="${rateset}" makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src_file}":RGS${inst}_BACKGROUND,M_LAMBDA,XDSP_CORR))"
            GEN_LCS+=("${rateset}")
        fi
    done

    # Check for unscheduled 'U' event files
    u_ids=$(ls *R[12]U*EVEN* 2>/dev/null | sed -nE 's/.*R[12](U[0-9]{3}).*/\1/p' | sort -u || true)
    if [ -n "${u_ids}" ]; then
        FOUND_U_EVENTS=true
        for uid in ${u_ids}; do
            for inst in 1 2; do
                src_file="$(ls *R${inst}${uid}*SRC* 2>/dev/null | head -n 1 || true)"
                table_file="$(ls *R${inst}${uid}*EVEN* 2>/dev/null | head -n 1 || true)"
                if [ -n "${src_file}" ] && [ -n "${table_file}" ]; then
                    rateset="rgs${inst}_bkg_lc${uid}.fit"
                    echo "Processing RGS${inst} Unscheduled (${uid}) event: ${table_file} -> ${rateset}"
                    evselect table="${table_file}" timebinsize=100 rateset="${rateset}" makeratecolumn=yes maketimecolumn=yes expression="(CCDNR==9)&&(REGION("${src_file}":RGS${inst}_BACKGROUND,M_LAMBDA,XDSP_CORR))"
                    GEN_LCS+=("${rateset}")
                fi
            done
        done
    fi

    # 5. User Notifications & Post-Processing Guidance
    if [ "${FOUND_U_EVENTS}" = true ]; then
        echo -e "\n${YELLOW}[WARNING] Unscheduled ('U') exposure events were detected and processed (${u_ids}).${NC}"
        echo -e "${YELLOW}Please verify if unscheduled exposures need special handling or merging during downstream spectral extraction.${NC}"
    fi

    echo -e "\n${GREEN}=================================================================${NC}"
    echo -e "${GREEN}  Light Curve Extraction Completed. Inspect Background Flares:   ${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    for lc in "${GEN_LCS[@]}"; do
        echo "Please use dsplot table=${lc} x=TIME y=RATE to check the flaring background count rate filter threshold. Suggested threshold: 0.1"
    done
done
