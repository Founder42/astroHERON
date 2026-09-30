#!/usr/bin/env bash
#==============================================================================
# Script: rgs_extract_step2_gtiFilt_regChk.sh
# Version: 2.0.0 (Unified Industrial CLI)
# Author: Fangzheng Shi & Logos
# Description: XMM-Newton RGS Pipeline Step 2 - Flaring GTI Filtering & Extraction Region Check
#==============================================================================

set -eo pipefail

# ---------------------------------------------------------
# Default values & color formatting
# ---------------------------------------------------------
OBS_IDS=""
IN_DIR=""
THRESHOLD=""
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
Usage: $(basename "$0") -o <OBSID> -i <DATA_DIR> -t <THRESHOLD> [options]

Mandatory Arguments:
  -o <OBSID>       Observation ID (single ID or quoted list, e.g. "0084030101 0900170101")
  -i <DATA_DIR>    Root directory containing raw/processing ODF observation data
  -t <THRESHOLD>   Flaring background count rate filter threshold (e.g. 0.1 or 0.15)

Optional Arguments:
  -c <CCF_PATH>    Path to SAS CCF calibration directory (default: \$SAS_CCFPATH)
  -h               Display this help manual and exit

Examples:
  # 1. Standard execution with threshold 0.1 counts/s
  $(basename "$0") -o 0084030101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM -t 0.1

  # 2. Specifying explicit CCF directory
  $(basename "$0") -o 0900170101 -i /Volumes/Pegasus/LLAGN_archive/M104/XMM -t 0.15 \\
                   -c /Users/fangzheng42/Program/SAS/ccf

  # 3. Batch processing multiple ObsIDs with same threshold
  $(basename "$0") -o "0084030101 0900170101" -i /Volumes/Pegasus/LLAGN_archive/M104/XMM -t 0.1
EOF
    exit "${1:-0}"
}

# ---------------------------------------------------------
# Helper: Positive numeric validation
# ---------------------------------------------------------
is_positive_number() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]] && [ "$1" != "0" ] && [ "$1" != "0.0" ] && [ "$1" != "0.00" ]
}

# ---------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------
while getopts ":o:i:t:c:h" opt; do
    case "${opt}" in
        o) OBS_IDS="${OPTARG}" ;;
        i) IN_DIR="${OPTARG}" ;;
        t) THRESHOLD="${OPTARG}" ;;
        c) CCF_PATH="${OPTARG}" ;;
        h) usage 0 ;;
        \?) echo -e "${RED}[ERROR] Invalid option: -${OPTARG}${NC}" >&2; usage 1 ;;
        :)  echo -e "${RED}[ERROR] Option -${OPTARG} requires an argument.${NC}" >&2; usage 1 ;;
    esac
done

# ---------------------------------------------------------
# Defensive Sanity Checks
# ---------------------------------------------------------
if [ -z "${OBS_IDS}" ] || [ -z "${IN_DIR}" ] || [ -z "${THRESHOLD}" ]; then
    echo -e "${RED}[ERROR] Missing mandatory arguments (-o, -i, -t).${NC}" >&2
    usage 1
fi

if [ ! -d "${IN_DIR}" ]; then
    echo -e "${RED}[ERROR] Specified data root directory does not exist: '${IN_DIR}'${NC}" >&2
    exit 1
fi

if ! is_positive_number "${THRESHOLD}"; then
    echo -e "${RED}[ERROR] Background filter threshold must be a positive number: '${THRESHOLD}'${NC}" >&2
    exit 1
fi

if [ -z "${CCF_PATH}" ] || [ ! -d "${CCF_PATH}" ]; then
    echo -e "${RED}[ERROR] SAS CCF calibration directory is invalid or not set: '${CCF_PATH}'. Specify via -c or export SAS_CCFPATH.${NC}" >&2
    exit 1
fi

# Verify SAS tools exist in PATH
for tool in tabgtigen rgsproc evselect; do
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
    echo -e "${BLUE}  Starting RGS Step 2 Processing for ObsID: ${obsid}${NC}"
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
    echo -e "${GREEN}[INFO] Flare Threshold    : ${THRESHOLD} counts/s${NC}"
    echo -e "${GREEN}[INFO] SAS CCF Path       : ${SAS_CCFPATH}${NC}"

    cd "${WORK_DIR}"

    # 1. Environment & Calibration Setup (Assign once at the beginning)
    if [ ! -f "ccf.cif" ]; then
        echo -e "${RED}[ERROR] 'ccf.cif' not found in $(pwd). Please run Step 1 (rgs_extract_step1.sh) first.${NC}" >&2
        exit 1
    fi
    export SAS_CCF="$(pwd)/ccf.cif"

    SUM_FILE="$(ls *SUM.SAS 2>/dev/null | head -n 1 || true)"
    if [ -z "${SUM_FILE}" ]; then
        echo -e "${RED}[ERROR] No '*SUM.SAS' file found in $(pwd). Please run Step 1 (rgs_extract_step1.sh) first.${NC}" >&2
        exit 1
    fi
    export SAS_ODF="$(pwd)/${SUM_FILE}"

    echo -e "${GREEN}[INFO] SAS_CCF set to     : ${SAS_CCF}${NC}"
    echo -e "${GREEN}[INFO] SAS_ODF set to     : ${SAS_ODF}${NC}"

    # 2. Flaring Background GTI Generation (tabgtigen)
    echo -e "${GREEN}[INFO] Generating auxiliary GTI tables (RATE < ${THRESHOLD})...${NC}"
    GTI_TABLES=()
    FOUND_U_EVENTS=false

    # Check for Scheduled 'S' light curves
    if [ -f "rgs1_bkg_lc.fit" ]; then
        echo "Creating rgs1_low.fit from rgs1_bkg_lc.fit..."
        tabgtigen table="rgs1_bkg_lc.fit" gtiset="rgs1_low.fit" expression="(RATE<${THRESHOLD})"
        GTI_TABLES+=("rgs1_low.fit")
    fi

    if [ -f "rgs2_bkg_lc.fit" ]; then
        echo "Creating rgs2_low.fit from rgs2_bkg_lc.fit..."
        tabgtigen table="rgs2_bkg_lc.fit" gtiset="rgs2_low.fit" expression="(RATE<${THRESHOLD})"
        GTI_TABLES+=("rgs2_low.fit")
    fi

    # Check for Unscheduled 'U' light curves
    u_lcs="$(ls rgs[12]_bkg_lcU*.fit 2>/dev/null || true)"
    if [ -n "${u_lcs}" ]; then
        FOUND_U_EVENTS=true
        for lc in ${u_lcs}; do
            [ -f "${lc}" ] || continue
            gti_set="${lc/_bkg_lc/_low}"
            echo "Creating ${gti_set} from ${lc}..."
            tabgtigen table="${lc}" gtiset="${gti_set}" expression="(RATE<${THRESHOLD})"
            GTI_TABLES+=("${gti_set}")
        done
    fi

    if [ "${#GTI_TABLES[@]}" -eq 0 ]; then
        echo -e "${RED}[ERROR] No background light curve files (rgs*_bkg_lc*.fit) found in $(pwd).${NC}" >&2
        echo -e "${RED}Please verify that Step 1 completed successfully and generated the light curves.${NC}" >&2
        exit 1
    fi

    # 3. Redo rgsproc from Stage 3 with GTI Filtering
    echo -e "${GREEN}[INFO] Re-running rgsproc from stage 3:filter with auxgtitables='${GTI_TABLES[*]}' (Log: gti_rgsproc_log)...${NC}"
    rgsproc entrystage=3:filter auxgtitables="${GTI_TABLES[*]}" > gti_rgsproc_log 2>&1

    # 4. Diagnostic Region Images Extraction (R1 Module)
    echo -e "${GREEN}[INFO] Generating extraction region check imagesets on RGS1...${NC}"
    src1="$(ls *R1S*SRC* 2>/dev/null | head -n 1 || true)"
    table1="$(ls *R1S*EVEN* 2>/dev/null | head -n 1 || true)"

    # Fallback to Unscheduled R1 if Scheduled is not available
    if [ -z "${src1}" ] || [ -z "${table1}" ]; then
        src1="$(ls *R1U*SRC* 2>/dev/null | head -n 1 || true)"
        table1="$(ls *R1U*EVEN* 2>/dev/null | head -n 1 || true)"
    fi

    if [ -z "${src1}" ] || [ -z "${table1}" ]; then
        echo -e "${RED}[ERROR] Could not locate RGS1 event list (*R1*EVEN*) or source list (*R1*SRC*) in $(pwd).${NC}" >&2
        exit 1
    fi

    echo "Using event list: ${table1}"
    echo "Using source list: ${src1}"

    # Total spatial
    echo "Extracting total spatial image -> rgs1_tot.fit..."
    evselect table="${table1}:EVENTS" imageset='rgs1_tot.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR'

    # Banana plot (PI vs dispersion, PI 0-3000, SRC3)
    echo "Extracting PI vs dispersion banana plot -> rgs1_pi.fit..."
    evselect table="${table1}:EVENTS" imageset='rgs1_pi.fit' xcolumn='M_LAMBDA' ycolumn='PI' yimagemin=0 yimagemax=3000 expression="REGION("${src1}":RGS1_SRC3_SPATIAL,M_LAMBDA,XDSP_CORR)"

    # Background plot
    echo "Extracting background region plot -> rgs1_bkg.fit..."
    evselect table="${table1}:EVENTS" imageset='rgs1_bkg.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' expression="REGION("${src1}":RGS1_BACKGROUND,M_LAMBDA,XDSP_CORR)"

    # Source plot (SRC3)
    echo "Extracting source region plot -> rgs1_src.fit..."
    evselect table="${table1}:EVENTS" imageset='rgs1_src.fit' xcolumn='M_LAMBDA' ycolumn='XDSP_CORR' expression="REGION("${src1}":RGS1_SRC3_SPATIAL,M_LAMBDA,XDSP_CORR)"

    # 5. User Notifications & Inspection Guidance
    if [ "${FOUND_U_EVENTS}" = true ]; then
        echo -e "\n${YELLOW}[WARNING] Unscheduled ('U') exposure events were filtered in this observation.${NC}"
        echo -e "${YELLOW}Please verify downstream spectral extraction for potential multiple exposure segments.${NC}"
    fi

    echo -e "\n${GREEN}=================================================================${NC}"
    echo -e "${GREEN}  GTI Filtering & Region Extraction Completed for ObsID: ${obsid}${NC}"
    echo -e "${GREEN}  To inspect the extraction region, please execute:              ${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    echo "rgsimplot endispset='rgs1_pi.fit' spatialset='rgs1_tot.fit' srcidlist='3' srclistset=${src1} device=/xs"
done
