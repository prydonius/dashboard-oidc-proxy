cfssl gencert -initca ca.json | cfssljson -bare ca
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
    -config=config.json -profile=server -hostname="kube-oidc-proxy.kube-oidc-proxy" \
    server.json | cfssljson -bare server
