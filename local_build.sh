#!/bin/bash

# Assistive script to build a Koha plugin .kpz package on your local machine
# or inside some containers but without CI/CD. For building in CI/CD, use the
# .github/workflows/main.yml file and push tag to master on GitHub.

DEFAULT_VERSION="${1:-0.0.1}"

perl_args=(-c)

# guess koha community repo path:
REPO_KOHA_COMMUNITY=~/git/KohaCommunity
[ ! -d "${REPO_KOHA_COMMUNITY}" ] && REPO_KOHA_COMMUNITY=~/git/Koha
[ -n "${REPO_KOHA_COMMUNITY}" ] && perl_args+=("-I${REPO_KOHA_COMMUNITY}")

# guess koha-plugin-KK-base repo path:
REPO_KK_BASE=~/git/koha-plugin-KK-base
[ ! -d "${REPO_KK_BASE}" ] && REPO_KK_BASE=""
[ -n "${REPO_KK_BASE}" ] && perl_args+=("-I${REPO_KK_BASE}")

# set base variables:
CURRENT_DIR="$(pwd)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PM_PATH="$(ls -1 "${SCRIPT_DIR}/Koha/Plugin/"*/*/*.pm)"
[ ! -f "${PM_PATH}" ] && { echo "Plugin file not found [${PM_PATH}]"; exit 1; }
PM_FILE="$(basename ${PM_PATH})"
PM_SUBFOLDER="${PM_FILE%.pm}"
PM_FOLDER="$(dirname ${PM_PATH})/${PM_SUBFOLDER}"
[ ! -d "${PM_FOLDER}" ] && { echo "Plugin folder not found [${PM_FOLDER}]"; exit 1; }
PM_FOLDER_RELATIVE="$(echo ${PM_PATH} | sed -e "s|${SCRIPT_DIR}/||")"
DATE="$(date +"%Y-%m-%d")"
VERSION="$(git -C "${SCRIPT_DIR}" describe --tags --abbrev=0 2>/dev/null | sed -e "s/v//")"
[ -z "${VERSION}" ] && { echo " - No version tag found, will default to ${DEFAULT_VERSION}"; VERSION="${DEFAULT_VERSION}"; }
RELEASE_FILE="koha-plugin-${PM_SUBFOLDER}-${VERSION}.kpz"

echo "Local plugin builder. Building '${PM_SUBFOLDER}' plugin version '${VERSION}'"
echo -n " - Release file: ${RELEASE_FILE} will be put in current directory."
[ -e ${RELEASE_FILE} ] && { echo " Old one removed."; rm ${RELEASE_FILE}; }
echo

if [ -n "${REPO_KOHA_COMMUNITY}" ]; then
    perl_args+=(-I"${SCRIPT_DIR}" "${PM_PATH}")
    if ! perl "${perl_args[@]}"; then
        echo "Perl syntax check failed!"
        exit 1
    fi
fi

TMP_DIR="$(mktemp -d)" || { echo "Failed to create temp directory"; exit 1; }
function cleanup {
    trap - EXIT
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

cp -r "${SCRIPT_DIR}/Koha" "${TMP_DIR}/."
SED_CMD=(sed -i)
[[ "$OSTYPE" == "darwin"* ]] && SED_CMD=(sed -i "")
"${SED_CMD[@]}" -e "s/{VERSION}/${VERSION}/g" "${TMP_DIR}/${PM_FOLDER_RELATIVE}" || { echo "Failed to set version in ${PM_FILE}"; exit 1; }
"${SED_CMD[@]}" -e "s/1900-01-01/${DATE}/g" "${TMP_DIR}/${PM_FOLDER_RELATIVE}" || { echo "Failed to set date in ${PM_FILE}"; exit 1; }
cd "${TMP_DIR}" || { echo "Failed to change directory"; exit 1; }
zip -qr "${CURRENT_DIR}/${RELEASE_FILE}" "Koha" || { echo "Failed to create zip file"; exit 1; }

cleanup
