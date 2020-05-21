# source https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
temp_subj="/C=DE/ST=Some-State/L=Some-City/O=Some-Organization/OU=Some-Department/emailAddress=none@none.com"
root_subj="$temp_subj"
mongodb_serv_subj="${temp_subj}/CN=mongodb"
mongo_express_serv_subj="${temp_subj}/CN=mongo-express"

# generate and self-sign root certificate
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj "$root_subj"

# generate mongodb key and self-signed certificate
mkdir -p mongodb
openssl genrsa -out mongodb/tls_key.pem 2048
openssl req -new -key mongodb/tls_key.pem -out mongodb/tls_cert.csr -subj "$mongodb_serv_subj"
openssl x509 -req -in mongodb/tls_cert.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out mongodb/tls_cert.pem -days 500 -sha256
cat mongodb/tls_key.pem mongodb/tls_cert.pem > mongodb/tls_key_cert.pem

mkdir -p mongo-express
openssl genrsa -out mongo-express/tls_key.pem 2048
openssl req -new -key mongo-express/tls_key.pem -out mongo-express/tls_cert.csr -subj "$mongo_express_serv_subj"
openssl x509 -req -in mongo-express/tls_cert.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out mongo-express/tls_cert.pem -days 500 -sha256
cat mongo-express/tls_key.pem mongo-express/tls_cert.pem > mongo-express/tls_key_cert.pem