# letsencrypt-wild-card-ssl-route-53

Reference url

https://medium.com/prog-code/lets-encrypt-wildcard-certificate-configuration-with-aws-route-53-9c15adb936a7

https://hub.docker.com/r/certbot/certbot/dockerfile

https://hub.docker.com/r/certbot/dns-route53/dockerfile

## Letsencrypt service account ###

    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: letsencrypt
      namespace: default
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: letsencrypt
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: letsencrypt
      namespace: default
 
### Letsencrypt job ###

    apiVersion: batch/v1
    kind: Job
    metadata:
      name: letsencrypt
      labels:
        app: letsencrypt
    spec:
      template:
        metadata:
          name: letsencrypt
          labels:
            app: letsencrypt
        spec:
          serviceAccountName: letsencrypt
          containers:
          - image: phanikumary1995/wild-ssl-route-53
            name: letsencrypt
            imagePullPolicy: Always
            env:
            - name: DOMAIN
              value: "*.example.com"
            - name: EMAIL
              value: exmaple@mail.com
            - name: SECRET
              value: example-com-cert
            - name: AWS_ACCESS_KEY_ID
              value: XXXXXXXXXX
            - name: AWS_SECRET_ACCESS_KEY
              value: XXXXXXXXXXXXXXXXXXXXX
          restartPolicy: Never
