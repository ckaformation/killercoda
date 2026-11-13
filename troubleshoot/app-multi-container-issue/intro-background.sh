#!/bin/bash
set -e

NS="tatooine"

cat > /root/wait-for-ready.sh <<'EOS'
#!/bin/bash
NS="tatooine"

echo "Préparation de l'environnement en cours..."
for i in $(seq 1 40); do
  POD=$(kubectl get pods -n "$NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$POD" ]; then
    RESTARTS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[?(@.name=="nginx")].restartCount}' 2>/dev/null)
    if [ -n "$RESTARTS" ] && [ "$RESTARTS" -ge 1 ] 2>/dev/null; then
      echo "Environnement prêt."
      exit 0
    fi
  fi
  sleep 5
done

echo "L'environnement met plus de temps que prévu à se préparer."
echo "Relance ce script dans quelques instants : ./wait-for-ready.sh"
exit 1
EOS
chmod +x /root/wait-for-ready.sh

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Création du déploiement twin-suns (2 conteneurs, conflit de port volontaire)"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: twin-suns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: twin-suns
  template:
    metadata:
      labels:
        app: twin-suns
    spec:
      containers:
      - name: httpd
        image: httpd:2-alpine
        ports:
        - containerPort: 80
      - name: nginx
        image: nginx:1-alpine
        ports:
        - containerPort: 80
EOF

echo "[prep] Environnement prêt (le conteneur nginx devrait échouer à démarrer)."
