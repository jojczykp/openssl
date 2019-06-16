#! /bin/bash

set -e

if [[ -z "${1}" ]]
then
    echo "Usage:"
    echo "    ${0} <dest-folder>"
    exit 1
fi

DEST_FOLDER="${1}"


gen_pin() {
    date +%Y%m%s%H%M%S%N | tr -d '\n'
}


cert_gen_ca() {
    NAME="$1"
    SUBJ="$2"

    echo "*** Generating Root CA Self-Signed certificate"
    echo "*** - name: ${NAME}"
    echo "*** - subject: ${SUBJ}"

    PIN="${NAME}.pin"
    KEY="${NAME}.key"
    CRT="${NAME}.crt"
    P12="${NAME}.p12"

    echo "* Password..."
    gen_pin > "${PIN}"

    echo "* Certificate..."
    openssl req \
        -newkey rsa:4096 -keyout "${KEY}" \
        -x509 -out "${CRT}" \
        -days 36500 -subj "${SUBJ}" \
        -passout "file:${PIN}"

    echo "* PKCS#12 Keystore..."
    openssl pkcs12 \
        -export -name "${NAME}" \
        -in "${CRT}" -inkey "${KEY}" -passin "file:${PIN}" \
        -out "${P12}" -passout "pass:$(cat "${PIN}")"
}


cert_gen_signed() {
    CA_NAME="$1"
    NAME="$2"
    SUBJ="$3"
    shift 3

    echo "*** Generating signed certificate"
    echo "*** - name: ${NAME}"
    echo "*** - subject: ${SUBJ}"
    echo "*** - signed by: ${CA_NAME}"
    echo "*** - alternative dns names: $@"

    CA_CRT="${CA_NAME}.crt"
    CA_KEY="${CA_NAME}.key"
    CA_PIN="${CA_NAME}.pin"

    CNF="${NAME}.cnf"
    PIN="${NAME}.pin"
    KEY="${NAME}.key"
    CSR="${NAME}.csr"
    CRT="${NAME}.crt"
    P12="${NAME}.p12"

    echo "* Config..."
    cat <<EOF > "${CNF}"
[req]
distinguished_name = req_distinguished_name
req_extensions = req_v3_ext

[req_distinguished_name]

[req_v3_ext]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

    while [[ -n "$1" ]]
    do
        ALT_NAME_CNT=$((ALT_NAME_CNT + 1))
        echo "DNS.${ALT_NAME_CNT} = $1" >> "${CNF}"
        shift
    done

    echo "* Password..."
    gen_pin > "${PIN}"

    echo "* Certificate Sign Request..."
    openssl req \
        -config "${CNF}" \
        -newkey rsa:4096 -keyout "${KEY}" \
        -out "${CSR}" \
        -subj "${SUBJ}" \
        -passout "file:${PIN}"

    echo "* Signed Certificate..."
    openssl x509 -req \
        -extfile "${CNF}" -extensions req_v3_ext \
        -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAcreateserial \
        -in "${CSR}" -passin "file:${CA_PIN}" \
        -out "${CRT}" \
        -days 36500 -sha512

    echo "* PKCS#12 Keystore..."
    openssl pkcs12 \
        -export -name "${NAME}" \
        -in "${CRT}" -inkey "${KEY}" -passin "file:${PIN}" \
        -out "${P12}" -passout "pass:$(cat "${PIN}")"
}


cd "${DEST_FOLDER}"

cert_gen_ca "ca" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=ca"
cert_gen_signed "ca" "site1" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site1" "site1.com" "*.site1.com"
cert_gen_signed "ca" "site2" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site2" "site2.com" "*.site2.com"
cert_gen_signed "ca" "site3" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site3" "site3.com" "*.site3.com"
