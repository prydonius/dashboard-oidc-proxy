# Kubernetes Dashboard over OIDC proxy

This walkthrough details setting up access to the Kubernetes Dashboard over an
OIDC impersonation proxy (https://github.com/jetstack/kube-oidc-proxy). This
allows users to login to the Kubernetes Dashboard using an OIDC identity
provider, even when configuring the Kubernetes API server for OIDC
authentication is not an available option (e.g. if on a managed service such as
GKE)

## Prerequisites

- a Kubernetes cluster (e.g. GKE)
- kubectl
- an OIDC identity provider (e.g. [Google OAuth App](https://console.cloud.google.com/apis/credentials))
- cfssl and cfssljson for generating certs

## 1. Generate certs

The first step is to generate TLS ceritifates for the OIDC proxy:

```
cd ./certs
sh gen-certs.sh
```

## 2. Fill in kube-oidc-proxy Secrets

Edit kube-oidc-proxy/secrets.yaml and fill in the serving TLS cert and key using
`certs/server.pem` and `certs/server-key.pem` respectively.

Fill in the OIDC Secret as per your identity provider. For oidc.username-claim,
use the claim from the OIDC token that represents the user (e.g. `email` for
Google).

## 3. Deploy the kube-oidc-proxy

Deploy the kube-oidc-proxy with this configuration:

```
kubectl apply -f ./kube-oidc-proxy
```

## 4. Deploy Kubernetes Dashboard

```
kubectl apply -f ./dashboard
```

Next we need to create the `kubernetes-dashboard-token-proxycert` Secret to
allow the Dashboard to correctly connect to proxy with the certs we generated.

```
# Get the existing Service Account secret, change UUID for the generated Secret name
kubectl get secret kubernetes-dashboard-token-UUID -o yaml > kubernetes-dashboard-token-proxycert.yaml
```

Now edit kubernetes-dashboard-token-proxycert.yaml to make the following changes:
- Change name to `kubernetes-dashboard-token-proxycert`
- Change type to `Opaque`
- Change ca.crt to `certs/ca.pem`

Create the Secret:

```
kubectl apply -f kubernetes-dashboard-token-proxycert.yaml
```

After some time, the Dashboard Pod should now become healthy.

## 5. Deploy keycloak-gatekeeper to perform OIDC login and forward to the dashboard

```
kubectl apply -f keycloak-gatekeeper/
```

## 6. Access the Dashboard through the proxy

For example:

```
kubectl port-forward svc/oidc-proxy-dashboard 8081:3000
```

Ensure you've configured the redirect URI with your identity provider correctly.
You'll be forwarded to your identity provider to login, and will be returned to
the Dashboard as a successfully logged in user.
