#!/bin/bash

if [[ -z $EMAIL || -z $DOMAIN || -z $SECRET || -z $AWS_ACCESS_KEY_ID || -z $AWS_SECRET_ACCESS_KEY ]]; then
        echo "EMAIL, DOMAIN, SECERT, AWS_ACCESS_KEY_ID and $AWS_SECRET_ACCESS_KEY env vars required"
        env
        exit 1
fi

echo "aws_access_key_id=${AWS_ACCESS_KEY_ID}" >> /opt/aws-config
echo "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" >> /opt/aws-config

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)


certbot certonly -d ${DOMAIN} --dns-route53  -m  ${EMAIL} --agree-tos --non-interactive --server https://acme-v02.api.letsencrypt.org/directory   || exit 1

kubectl get secret  ${SECRET}

if [ $? = 0 ]
                then
                echo "============================="
                echo "${SECRET} is already created "
                echo "============================="
                else

                echo "============================="
                echo "${SECRET} is creating "
                echo "============================="
kubectl create secret generic ${SECRET}

                echo "======================="
                echo "${SECRET} is created "
                echo "======================="

fi



CERTPATH=/etc/letsencrypt/live/*

ls $CERTPATH || exit 1

cat /secret-patch-template.json | \
        sed "s/NAMESPACE/${NAMESPACE}/" | \
        sed "s/NAME/${SECRET}/" | \
        sed "s/TLSCERT/$(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')/" | \
        sed "s/TLSKEY/$(cat ${CERTPATH}/privkey.pem |  base64 | tr -d '\n')/" \
        > /secret-patch.json

ls /secret-patch.json || exit 1

# update secret
curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/secret-patch.json https://kubernetes.default/api/v1/namespaces/${NAMESPACE}/secrets/${SECRET}
