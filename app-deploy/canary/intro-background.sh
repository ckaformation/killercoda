#!/bin/bash
# ============================================================================
# Preparation silencieuse (tout dans le namespace default) :
#   - /root/wait-for-prep.sh : depose des le debut ; il attend un fichier
#     sentinelle (/tmp/.scenario-prep-done) cree tout a la fin de ce script,
#     une fois que le Service repond reellement sur son NodePort.
#     L'etape 1 invite l'eleve a le lancer.
#   - lien symbolique k -> kubectl
#   - 2 ConfigMaps contenant chacune un index.html :
#       x-wing-current-page : "version : Current"
#       x-wing-canary-page  : "version : Canary"
#     (la seconde ne sert qu'a partir de l'etape 1, quand l'eleve cree la
#     version canary).
#   - /root/x-wing-current.yaml : manifeste du Deployment x-wing-current,
#     que l'eleve copie a l'etape 1 pour creer x-wing-canary. Le mot
#     "current" y apparait 5 fois (nom, 3 labels track, nom de la ConfigMap)
#     et nulle part ailleurs : un seul remplacement current -> canary suffit.
#   - Deployment x-wing-current : 4 replicas nginx:alpine, labels
#     app=x-wing + track=current (selector compris), ConfigMap montee dans
#     /usr/share/nginx/html, readinessProbe httpGet / sur le port 80.
#   - Service x-wing : NodePort 30080, selector app=x-wing SEUL : il vise les
#     pods des deux versions, la repartition suit donc le nombre de pods
#     prets de chaque cote.
#   - /etc/hosts : "yavin" -> InternalIP du noeud (meme principe que
#     blue-green et api-gateway : on n'appelle pas le NodePort sur localhost).
# ============================================================================

rm -f /tmp/.scenario-prep-done

cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours (ConfigMaps, x-wing-current, Service x-wing)..."
TIMEOUT=240
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done
if [ -f /tmp/.scenario-prep-done ]; then
  echo "C'est pret ! Tu peux continuer."
else
  echo "La preparation prend plus de temps que prevu. Patiente encore un peu avant de continuer."
fi
WAITEOF
chmod +x /root/wait-for-prep.sh

ln -sf "$(which kubectl)" /usr/local/bin/k

# --- Attendre l'API et le noeud ---
for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

# --- Les deux pages ---
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: x-wing-current-page
data:
  index.html: |
    version : Current
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: x-wing-canary-page
data:
  index.html: |
    version : Canary
EOF

# --- Manifeste de la version actuelle (laisse a l'eleve) ---
cat > /root/x-wing-current.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-wing-current
  labels:
    app: x-wing
    track: current
spec:
  replicas: 4
  selector:
    matchLabels:
      app: x-wing
      track: current
  template:
    metadata:
      labels:
        app: x-wing
        track: current
    spec:
      containers:
      - name: x-wing
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 3
        volumeMounts:
        - name: page
          mountPath: /usr/share/nginx/html
      volumes:
      - name: page
        configMap:
          name: x-wing-current-page
EOF

kubectl apply -f /root/x-wing-current.yaml

# --- Service NodePort commun aux deux versions ---
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: x-wing
spec:
  type: NodePort
  selector:
    app: x-wing
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

# --- Nom yavin -> IP interne du noeud ---
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
sed -i '/[[:space:]]yavin$/d' /etc/hosts
echo "${NODE_IP} yavin" >> /etc/hosts

kubectl rollout status deployment/x-wing-current --timeout=180s

# --- Attendre que le NodePort reponde (120 s max) ---
# Si ce n'est jamais le cas, la sentinelle n'est pas creee et
# wait-for-prep.sh finit par afficher son message de depassement.
for i in $(seq 1 60); do
  if curl -s --max-time 3 http://yavin:30080 2>/dev/null | grep -q "version : Current"; then
    touch /tmp/.scenario-prep-done
    break
  fi
  sleep 2
done

exit 0
