#!/bin/bash
# ============================================================================
# Preparation silencieuse (tout dans le namespace default) :
#   - /root/wait-for-prep.sh : depose des le debut ; il attend un fichier
#     sentinelle (/tmp/.scenario-prep-done) cree tout a la fin de ce script,
#     une fois que le Service repond reellement sur son NodePort.
#     L'etape 1 invite l'eleve a le lancer.
#   - lien symbolique k -> kubectl
#   - 2 ConfigMaps (lightsaber-blue-page, lightsaber-green-page) contenant
#     chacune un index.html qui affiche la version ("Sabre laser - version
#     blue" / "... green"), montees dans /usr/share/nginx/html.
#   - 2 Deployments nginx:alpine de 2 replicas :
#       lightsaber-blue  : labels app=lightsaber, version=blue
#       lightsaber-green : labels app=lightsaber, version=green
#     Le selector de chaque Deployment porte les DEUX labels : les deux
#     Deployments ne se marchent pas dessus, et "kubectl expose deployment
#     lightsaber-green" (etape 3) recopie un selector qui ne vise que green.
#     readinessProbe httpGet / sur le port 80 : seuls les pods prets
#     recoivent du trafic.
#   - Service lightsaber : NodePort 30080, selector app=lightsaber,
#     version=blue.
#   - /etc/hosts : "jedi-temple" -> InternalIP du noeud (meme principe que
#     le scenario api-gateway : on n'appelle pas le NodePort sur localhost).
# ============================================================================

rm -f /tmp/.scenario-prep-done

cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours (lightsaber-blue, lightsaber-green, Service lightsaber)..."
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

# --- Une version de l'application : ConfigMap (page) + Deployment ---
# $1 = couleur de la version (blue ou green)
deploy_version() {
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: lightsaber-$1-page
data:
  index.html: |
    Sabre laser - version $1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lightsaber-$1
  labels:
    app: lightsaber
    version: $1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: lightsaber
      version: $1
  template:
    metadata:
      labels:
        app: lightsaber
        version: $1
    spec:
      containers:
      - name: lightsaber
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
          name: lightsaber-$1-page
EOF
}

deploy_version blue
deploy_version green

# --- Service NodePort qui pointe sur blue ---
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: lightsaber
spec:
  type: NodePort
  selector:
    app: lightsaber
    version: blue
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

# --- Nom jedi-temple -> IP interne du noeud ---
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
sed -i '/[[:space:]]jedi-temple$/d' /etc/hosts
echo "${NODE_IP} jedi-temple" >> /etc/hosts

kubectl rollout status deployment/lightsaber-blue --timeout=180s
kubectl rollout status deployment/lightsaber-green --timeout=180s

# --- Attendre que le NodePort reponde avec la version blue (120 s max) ---
# Si ce n'est jamais le cas, la sentinelle n'est pas creee et
# wait-for-prep.sh finit par afficher son message de depassement.
for i in $(seq 1 60); do
  if curl -s --max-time 3 http://jedi-temple:30080 2>/dev/null | grep -q "version blue"; then
    touch /tmp/.scenario-prep-done
    break
  fi
  sleep 2
done

exit 0
