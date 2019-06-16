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

    echo "* Password..."
    gen_pin > "${NAME}.pin"

    echo "* Certificate..."
    openssl req \
        -newkey rsa:4096 -keyout "${NAME}.key" \
        -x509 -out "${NAME}.crt" \
        -days 36500 -subj "${SUBJ}" \
        -passout "file:${NAME}.pin"

    echo "* PKCS#12 Keystore..."
    openssl pkcs12 \
        -export -name "${NAME}" \
        -in "${NAME}.crt" -inkey "${NAME}.key" -passin "file:${NAME}.pin" \
        -out "${NAME}.pkcs12" -passout "pass:$(cat "${NAME}.pin")"

}


cert_gen_signed() {
    CA="$1"
    NAME="$2"
    SUBJ="$3"
    shift 3

    echo "*** Generating certificate '${NAME}' with subject '${SUBJ}' signed by '${CA}'"
    echo "*** - name: ${NAME}"
    echo "*** - subject: ${SUBJ}"
    echo "*** - signed by: ${CA}"
    echo "*** - alternative dns names: $@"

    echo "* Config..."
    cat <<EOF > "${NAME}.cnf"
[req]
distinguished_name = req_distinguished_name
req_extensions = req_v3_ext

[req_distinguished_name]

[req_v3_ext]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${NAME}
EOF

    ALT_NAME_CNT=1
    while [[ -n "${1}" ]]
    do
        ALT_NAME_CNT=$((ALT_NAME_CNT + 1))
        echo "DNS.${ALT_NAME_CNT} = ${1}" >> "${NAME}.cnf"
        shift
    done

    echo "* Password..."
    gen_pin > "${NAME}.pin"

    echo "* Certificate Sign Request..."
    openssl req \
        -config "${NAME}.cnf" \
        -newkey rsa:4096 -keyout "${NAME}.key" \
        -out "${NAME}.csr" \
        -subj "${SUBJ}" \
        -passout "file:${NAME}.pin"

    echo "* Signed Certificate..."
    openssl x509 -req \
        -extfile "${NAME}.cnf" -extensions req_v3_ext \
        -CA "${CA}.crt" -CAkey "${CA}.key" -CAcreateserial \
        -in "${NAME}.csr" -passin "file:${CA}.pin" \
        -out "${NAME}.crt" \
        -days 36500 -sha512

    echo "* PKCS#12 Keystore..."
    openssl pkcs12 \
        -export -name "${NAME}" \
        -in "${NAME}.crt" -inkey "${NAME}.key" -passin "file:${NAME}.pin" \
        -out "${NAME}.pkcs12" -passout "pass:$(cat "${NAME}.pin")"
}


cd "${DEST_FOLDER}"

cert_gen_ca "ca" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=ca"
cert_gen_signed "ca" "site1" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site1" "site1.com" "*.site1.com"
cert_gen_signed "ca" "site2" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site2" "site2.com" "*.site2.com"
cert_gen_signed "ca" "site3" "/C=PL/L=Krakow/O=alterbit/OU=security/CN=site3" "site3.com" "*.site3.com"

