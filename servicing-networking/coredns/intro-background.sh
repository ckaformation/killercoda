#!/bin/bash
# Prépare l'environnement en arrière-plan :
# - injecte une directive Corefile inconnue dans le ConfigMap coredns
#   (kube-system) et force un rollout pour provoquer un CrashLoopBackOff
# - déploie une application pré-existante (namespace death-star) dont le
#   sidecar sondera le service que l'élève créera à l'étape 2
set -e

SENTINEL="/root/.prep-done"

rm -f "$SENTINEL"

# wait-for-prep.sh est écrit directement ici (voir leçon apprise sur le
# scénario Gateway API : les fichiers du dépôt ne sont pas copiés
# automatiquement sur la VM).
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

echo "[prep] Attente que CoreDNS soit initialement opérationnel"
kubectl -n kube-system rollout status deployment/coredns --timeout=120s

echo "[prep] Injection d'une directive Corefile inconnue dans le ConfigMap coredns"
ORIG=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')
# Insère la ligne juste après la toute première accolade ouvrante du
# Corefile (l'ouverture du bloc serveur), quel que soit le contenu exact
# du reste du fichier (qui peut varier selon la version de kubeadm).
BROKEN=$(printf '%s' "$ORIG" | sed '0,/{/s//{\n    holocron/')
kubectl create configmap coredns -n kube-system --from-literal=Corefile="$BROKEN" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Redémarrage forcé de CoreDNS pour appliquer la config cassée"
kubectl -n kube-system rollout restart deployment/coredns
# On ne fait volontairement PAS de "rollout status" ici : les nouveaux
# pods vont partir en CrashLoopBackOff, c'est l'objet de l'étape 1.

echo "[prep] Déploiement de l'application pré-existante (namespace death-star)"
kubectl create namespace death-star --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n death-star -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sensor-array
  labels: {app: sensor-array}
spec:
  replicas: 1
  selector: {matchLabels: {app: sensor-array}}
  template:
    metadata: {labels: {app: sensor-array}}
    spec:
      containers:
      - name: sensor-array
        image: nginx:1-alpine
        ports: [{containerPort: 80}]
      - name: probe-droid
        image: busybox:1.36
        command: ["sh", "-c"]
        args:
        - |
          while true; do
            if [ -n "$TARGET_URL" ]; then
              echo "$(date -Iseconds) test de connexion vers $TARGET_URL"
              if wget -q -T 3 -O - "http://$TARGET_URL/" >/dev/null 2>&1; then
                echo "$(date -Iseconds) OK: reponse recue de $TARGET_URL"
              else
                echo "$(date -Iseconds) ECHEC: impossible de joindre $TARGET_URL"
              fi
            else
              echo "$(date -Iseconds) TARGET_URL non defini, en attente..."
            fi
            sleep 5
          done
        env:
        - name: TARGET_URL
          value: ""
EOF

kubectl -n death-star rollout status deployment/sensor-array --timeout=120s

touch "$SENTINEL"
echo "[prep] Environnement prêt (CoreDNS volontairement cassé pour l'étape 1)."
