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
echo ""

openssl x509 -in "${CERT_PATH}" -noout -text

