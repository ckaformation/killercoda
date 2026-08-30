#!/bin/bash
# Prépare l'environnement en arrière-plan. Écrit un sentinel à la fin ;
# l'élève l'attend via wait-for-prep.sh (étape 1), conformément au
# pattern déjà utilisé dans les autres scénarios de ce cursus.
set -e

SENTINEL="/root/.prep-done"
GATEWAY_API_VERSION="v1.6.1"
TRAEFIK_NS="traefik"
APP_NS="imagine-app"

rm -f "$SENTINEL"

# wait-for-prep.sh n'est pas livré via un mécanisme "assets" (syntaxe non
# confirmée pour ce backend) : ce script, dont l'exécution automatique au
# démarrage de la VM est déjà acquise, l'écrit lui-même sur disque.
cat > /root/wait-for-prep.sh <<'EOS'
#!/bin/bash
SENTINEL="/root/.prep-done"

echo "Préparation de l'environnement en cours (CRDs Gateway API, Traefik, application de démo)..."
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

echo "[prep] Installation des CRDs Gateway API (canal standard, ${GATEWAY_API_VERSION})"
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

for crd in gatewayclasses.gateway.networking.k8s.io \
           gateways.gateway.networking.k8s.io \
           grpcroutes.gateway.networking.k8s.io \
           httproutes.gateway.networking.k8s.io \
           referencegrants.gateway.networking.k8s.io; do
  echo "[prep] Attente Established : crd/${crd}"
  kubectl wait --for=condition=Established --timeout=90s "crd/${crd}"
done

echo "[prep] Ajout du repo Helm Traefik"
helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl create namespace "${TRAEFIK_NS}" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Installation de Traefik avec le provider Gateway API activé"
helm upgrade --install traefik traefik/traefik \
  -n "${TRAEFIK_NS}" \
  --set providers.kubernetesIngress.enabled=false \
  --set providers.kubernetesGateway.enabled=true \
  --set gateway.enabled=false \
  --set gatewayClass.enabled=true

echo "[prep] Attente du rollout du Deployment traefik"
kubectl -n "${TRAEFIK_NS}" rollout status deployment/traefik --timeout=180s

# Filet de sécurité NON VÉRIFIÉ EN CONDITIONS RÉELLES : sur certaines
# versions du chart, la création de la GatewayClass pourrait être liée
# à gateway.enabled malgré gatewayClass.enabled=true. Si la
# GatewayClass n'apparaît pas, on réinstalle avec gateway.enabled=true
# puis on supprime la Gateway par défaut ainsi créée.
if ! kubectl get gatewayclass traefik >/dev/null 2>&1; then
  echo "[prep] GatewayClass absente : repli avec gateway.enabled=true"
  helm upgrade --install traefik traefik/traefik \
    -n "${TRAEFIK_NS}" \
    --set providers.kubernetesIngress.enabled=false \
    --set providers.kubernetesGateway.enabled=true \
    --set gateway.enabled=true \
    --set gatewayClass.enabled=true
  kubectl -n "${TRAEFIK_NS}" rollout status deployment/traefik --timeout=180s
  kubectl delete gateway traefik -n "${TRAEFIK_NS}" --ignore-not-found
fi

echo "[prep] Attente GatewayClass/traefik Accepted"
kubectl wait --for=condition=Accepted --timeout=90s gatewayclass/traefik

echo "[prep] Patch du Service traefik en NodePort (80->30080, 443->30443)"
kubectl -n "${TRAEFIK_NS}" patch svc traefik --type merge -p \
  '{"spec":{"type":"NodePort","ports":[{"name":"web","port":80,"targetPort":"web","nodePort":30080,"protocol":"TCP"},{"name":"websecure","port":443,"targetPort":"websecure","nodePort":30443,"protocol":"TCP"}]}}'

echo "[prep] Vérification de /etc/hosts pour imagine.app"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if ! grep -qE '(^|[[:space:]])imagine\.app([[:space:]]|$)' /etc/hosts; then
  echo "${NODE_IP} imagine.app" >> /etc/hosts
  echo "[prep] Ligne ajoutée à /etc/hosts : ${NODE_IP} imagine.app"
else
  echo "[prep] imagine.app déjà présent dans /etc/hosts"
fi

echo "[prep] Création du namespace applicatif ${APP_NS}"
kubectl create namespace "${APP_NS}" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Déploiement des composants applicatifs (admin, api, web-v1, web-v2)"
kubectl apply -n "${APP_NS}" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin
  labels: {app: admin}
spec:
  replicas: 1
  selector: {matchLabels: {app: admin}}
  template:
    metadata: {labels: {app: admin}}
    spec:
      containers:
      - name: admin
        image: hashicorp/http-echo:1.0
        args: ["-listen=:7777", "-text=Welcome to the admin"]
        ports: [{containerPort: 7777}]
---
apiVersion: v1
kind: Service
metadata:
  name: admin
spec:
  selector: {app: admin}
  ports: [{port: 7777, targetPort: 7777}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels: {app: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:1.0
        args: ["-listen=:8080", "-text=Welcome to the api"]
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector: {app: api}
  ports: [{port: 8080, targetPort: 8080}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-v1
  labels: {app: web-v1}
spec:
  replicas: 1
  selector: {matchLabels: {app: web-v1}}
  template:
    metadata: {labels: {app: web-v1}}
    spec:
      containers:
      - name: web-v1
        image: hashicorp/http-echo:1.0
        args: ["-listen=:80", "-text=Welcome to the website - v1"]
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: web-v1
spec:
  selector: {app: web-v1}
  ports: [{port: 80, targetPort: 80}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-v2
  labels: {app: web-v2}
spec:
  replicas: 1
  selector: {matchLabels: {app: web-v2}}
  template:
    metadata: {labels: {app: web-v2}}
    spec:
      containers:
      - name: web-v2
        image: hashicorp/http-echo:1.0
        args: ["-listen=:80", "-text=Welcome to the website - v2"]
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: web-v2
spec:
  selector: {app: web-v2}
  ports: [{port: 80, targetPort: 80}]
EOF

kubectl -n "${APP_NS}" rollout status deployment/admin --timeout=120s
kubectl -n "${APP_NS}" rollout status deployment/api --timeout=120s
kubectl -n "${APP_NS}" rollout status deployment/web-v1 --timeout=120s
kubectl -n "${APP_NS}" rollout status deployment/web-v2 --timeout=120s

touch "$SENTINEL"
echo "[prep] Environnement prêt."
