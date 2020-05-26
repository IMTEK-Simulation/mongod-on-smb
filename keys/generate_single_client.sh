#!/bin/bash
set -x
# generate root certificate and derived set of self-signed certificates for testing purposes

# sources:
# - https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
# - http://apetec.com/support/GenerateSAN-CSR.htm
temp_subj="/C=DE/ST=Baden-Wuerttemberg/L=Freiburg i. Br./O=University of Freiburg/OU=IMTEK Simulation/emailAddress=johannes.hoermann@imtek.uni-freiburg.de"

subj="${temp_subj}/CN=localhost"
subdir="$(date +%Y%m%d%H%M)-client-cert"


mkdir -p "${subdir}"
PASSW=$(openssl rand -base64 32)
echo "$PASSW" > "${subdir}/passw"

# generate key
openssl genrsa -out "${subdir}/tls_key.pem" 2048
# generate certificate request
openssl req -new -key "${subdir}/tls_key.pem" -out "${subdir}/tls_cert.csr" -config openssl.cnf -subj "${subj}" -batch
# print request to stdout
openssl req -text -noout -in "${subdir}/tls_cert.csr"
# generate self-signed certifictae
openssl x509 -req -in "${subdir}/tls_cert.csr" -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out "${subdir}/tls_cert.pem" -days 500 -sha256 -extensions v3_req -extfile openssl.cnf
# concatenate key and signed certificate in simple file
cat "${subdir}"/tls_key.pem "${subdir}/tls_cert.pem" > "${subdir}/tls_key_cert.pem"
# concatenate key and signed certificate in p12 file
openssl pkcs12 -export -in "${subdir}/tls_cert.pem" -inkey "${subdir}/tls_key_cert.pem" -out "${subdir}/tls_key_cert.p12" -password pass:$PASSW
