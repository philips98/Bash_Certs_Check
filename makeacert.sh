#!/bin/bash

if [ -z "$1" ]
  then
    echo "Certificate name cannot be blank!"
    else
    openssl genrsa -out $1.key 2048
	openssl req -new -key $1.key -out $1.csr
	openssl x509 -req -in $1.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out $1.crt -days ${2:-1} -sha256
fi



