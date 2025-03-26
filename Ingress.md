## Ingress Controller installation

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/baremetal/deploy.yaml
```

## Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: "carapp.192.168.1.100.nip.io"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: car-rental-svc
            port:
              number: 80
  - host: "bookapp.192.168.1.100.nip.io"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: book-store-svc
            port:
              number: 80
  - host: "appx.192.168.1.100.nip.io"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: appx-svc
            port:
              number: 80

```
