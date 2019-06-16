#! /bin/bash

set -e


if [[ -z "${1}" ]]
then
    echo "Usage:"
    echo "    ${0} <path>"
    echo "Where:"
    echo "    <path> - path to openssl cert file (*.crt, *.cer, *.pem, ...)"
    exit 1
fi

CERT_PATH="${1}"
echo "Cert path: ${CERT_PATH}"

PIN_PATH="${1%%\.*}.pin"
echo -n "PIN path: ${PIN_PATH} "

if [[ -f "${PIN_PATH}" ]]
then
    PIN_ARG="-password "file:${PIN_PATH}""
    echo "(preset)"
else
    echo "(not found)"
fi

echo ""

openssl pkcs12 -info -nokeys -in "${CERT_PATH}" ${PIN_ARG}

