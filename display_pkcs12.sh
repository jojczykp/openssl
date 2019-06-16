#! /bin/bash

set -e


if [[ -z "${1}" ]]
then
    echo "Usage:"
    echo "    ${0} <path>"
    echo "Where:"
    echo "    <path> - path to openssl cert file (*.p12, pkcs12, ...)"
    echo ""
    echo "  If optional *.pin file is present, it's content is taken as password."
    exit 1
fi

CERT_PATH="${1}"
echo "Cert path: ${CERT_PATH}"

PIN_PATH="${1%\.*}.pin"
echo -n "PIN path: ${PIN_PATH} "

if [[ -f "${PIN_PATH}" ]]
then
    PIN_ARG="-password "file:${PIN_PATH}""
    echo "(found)"
else
    echo "(not found)"
fi

echo ""

openssl pkcs12 -info -nokeys -in "${CERT_PATH}" ${PIN_ARG}
