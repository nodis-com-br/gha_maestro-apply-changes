#!/usr/bin/env bash
set -e

UPGRADE=()
PRE_UNINSTALL=()
UNINSTALL=()

TEMP_DIR=./temp
MANIFEST_EXT=yaml
DEFAULT_IFS=${IFS}


pip install -i "https://${NODIS_PYPI_USER}:${NODIS_PYPI_PASSWORD}@${NODIS_PYPI_HOST}/simple" maestro

IFS=$'\n'
for LINE in `git diff --name-status -C HEAD^ HEAD | egrep '.*\/.*$' | egrep -v '.github/workflows'`;  do

    echo ${LINE}

    OPERATION=`echo ${LINE} | awk '{print $1}'`

    FILE=`echo ${LINE} | awk '{print $2}'`
    FILE_EXT=${FILE##*.}

    if [[ ${FILE_EXT} =~ ${MANIFEST_EXT} ]]; then

        [[ ${OPERATION} =~ (A|M) ]] && UPGRADE+=(${FILE})
        [[ ${OPERATION} = "D" ]] && PRE_UNINSTALL+=(${FILE})

    fi

    if [[ ${OPERATION} =~ ^(R|C) ]]; then

        NEW_FILE=`echo ${LINE} | awk '{print $3}'`
        NEW_FILE_EXT=${NEW_FILE##*.}

        [[ ${NEW_FILE_EXT} =~ ${MANIFEST_EXT} ]] && UPGRADE+=(${NEW_FILE})
        [[ ${OPERATION} =~ ^R && ${FILE_EXT} =~ ${MANIFEST_EXT} && ${NEW_FILE_EXT} != ${FILE_EXT} ]] && PRE_UNINSTALL+=(${NEW_FILE})

    fi

done
IFS=${DEFAULT_IFS}


if [[ ${#UPGRADE[@]} -gt 0 ]]; then
   maestro -u upgrade ${MAESTRO_OPTIONS} -f ${UPGRADE[@]}
fi

if [[ ${#PRE_UNINSTALL[@]} -gt 0 ]]; then

    mkdir -p ${TEMP_DIR}

    for F in ${PRE_UNINSTALL[@]}; do

        if ! [[ -f ${F} ]]; then
            IFS=$'\n'
            for COMMIT in `git log --skip=1 --format=oneline | awk '{print $1;}'`; do
                if git show ${COMMIT}:${F} 2> /dev/null | install -D /dev/stdin ${TEMP_DIR}/${F}; then
                    UNINSTALL+=("${TEMP_DIR}/${F}")
                    break
                fi
            done
            IFS=${DEFAULT_IFS}
        else
            UNINSTALL+=(${F})
        fi

    done

    maestro -u uninstall ${MAESTRO_OPTIONS} -f ${UNINSTALL[@]}

    rm -rf ${TEMP_DIR}

fi
