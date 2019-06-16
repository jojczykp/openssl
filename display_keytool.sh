#! /bin/bash

set -e


if [[ -z "${1}" ]]
then
    echo "Usage:"
    echo "    ${0} <path>"
    echo "Where:"
    echo "    <path> - path to keytool cert file (*.jks, *.pkcs, *.p12, ...)"
    echo ""
    echo "  If optional *.pin file is present, it's content is taken as password."
    exit 1
fi

CERT_PATH="${1}"
echo "Cert path: ${CERT_PATH}"

PIN_PATH="${1%%\.*}.pin"
echo -n "PIN path: ${PIN_PATH} "

if [[ -f "${PIN_PATH}" ]]
then
    PIN_ARG="-storepass '$(cat "${PIN_PATH}")'"
    echo " (preset)"
else
    echo " (not found)"
fi

echo ""

keytool -list -keystore "${CERT_PATH}" -v ${PIN_ARG}

