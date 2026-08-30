#!/bin/bash
set -e

SENTINEL="/root/.prep-done"
NS="outer-rim"

rm -f "$SENTINEL"

cat > /root/wait-for-prep.sh <<'EOS'
#!/bin/bash
SENTINEL="/root/.prep-done"

echo "Préparation de l'environnement en cours..."
for i in $(seq 1 60); do
  if [ -f "$SENTINEL" ]; then
    echo "Environnement prêt."
    exit 0
  fi
  sleep 5
done

echo "L'environnement met plus de temps que prévu à se préparer."
echo "Relance ce script dans quelques instants : ./wait-for-prep.sh"
exit 1
EOS
chmod +x /root/wait-for-prep.sh

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Création du ConfigMap de configuration nginx"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: hologram-nginx-conf
data:
  default.conf: |
    server {
        listen 443 ssl;
        server_name hologram.local;

        ssl_certificate     /etc/nginx/certs/tls.crt;
        ssl_certificate_key /etc/nginx/certs/tls.key;
        ssl_protocols       TLSv1.2 TLSv1.3;

        location / {
            return 200 "Transmission recue depuis hologram.local\n";
            add_header Content-Type text/plain;
        }
    }
EOF

echo "[prep] Création du Deployment (référence un Secret TLS qui n'existe pas encore)"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hologram
  labels: {app: hologram}
spec:
  replicas: 1
  selector: {matchLabels: {app: hologram}}
  template:
    metadata: {labels: {app: hologram}}
    spec:
      containers:
      - name: hologram
        image: nginx:alpine
        ports: [{containerPort: 443}]
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
        - name: tls-certs
          mountPath: /etc/nginx/certs
          readOnly: true
      volumes:
      - name: nginx-conf
        configMap:
          name: hologram-nginx-conf
      - name: tls-certs
        secret:
          secretName: hologram-tls
EOF

echo "[prep] Création du Service"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: hologram
spec:
  selector: {app: hologram}
  ports: [{port: 443, targetPort: 443}]
EOF

touch "$SENTINEL"
echo "[prep] Environnement prêt (le pod hologram reste bloqué : Secret hologram-tls manquant, c'est volontaire)."
