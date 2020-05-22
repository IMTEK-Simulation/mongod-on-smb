# generate root certificate and derived set of self-signed certificates for testing purposes

# source https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
temp_subj="/C=DE/ST=Some-State/L=Some-City/O=Some-Organization/OU=Some-Department/emailAddress=none@none.com"
root_subj="$temp_subj"

subj_suffix_arr=( "/CN=mongodb" "/CN=mongo-express" "/CN=mongo-express" )
subdir_arr=( "mongodb" "mongo_express_inwards" "mongo_express_outwards" )

# generate and self-sign root certificate
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj "$root_subj"

for ((i=0;i<${#subj_suffix_arr[@]};++i)); do
    subj="${temp_subj}${subj_suffix_arr[i]}"
    subdir="${subdir_arr[i]}"

    # generate mongodb key and self-signed certificate
    mkdir -p "${subdir}"
    openssl genrsa -out "${subdir}"/tls_key.pem 2048
    openssl req -new -key "${subdir}"/tls_key.pem -out "${subdir}"/tls_cert.csr -subj "${subj}"
    openssl x509 -req -in "${subdir}"/tls_cert.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out "${subdir}"/tls_cert.pem -days 500 -sha256
    cat "${subdir}"/tls_key.pem "${subdir}"/tls_cert.pem > "${subdir}"/tls_key_cert.pem
done