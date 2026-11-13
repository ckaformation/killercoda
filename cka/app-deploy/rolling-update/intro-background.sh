#!/bin/bash
# ============================================================================
# Preparation silencieuse (tout dans le namespace default) :
#   - /root/wait-for-prep.sh : depose des le debut ; il attend un fichier
#     sentinelle (/tmp/.scenario-prep-done) cree tout a la fin de ce script,
#     une fois que le pod de tie-fighter est effectivement en
#     CrashLoopBackOff. L'etape 1 invite l'eleve a le lancer.
#   - lien symbolique k -> kubectl
#   - millennium-falcon : 2 replicas, nginx:alpine, APP_RELEASE="v2",
#     strategie Recreate.
#   - death-star : 1 replica, deployee en APP_RELEASE="v1" (rollout termine),
#     puis MIS EN PAUSE, puis modifie (APP_RELEASE="v2"). Tant que le
#     deployment est en pause, la modification est enregistree dans le spec
#     mais aucun nouveau ReplicaSet (donc aucune nouvelle revision) n'est
#     cree : la revision 2 n'apparait qu'au "rollout resume".
#   - tie-fighter : 1 replica, strategie Recreate, 4 revisions creees dans
#     l'ordre :
#       1 = initial deployment    (APP_RELEASE=v1)
#       2 = v2 config changes     (APP_RELEASE=v2)
#       3 = v3 rollout            (APP_RELEASE=v3)
#       4 = v3 hotfix             (APP_RELEASE=v3 + commande nginx invalide)
#     Les libelles sont poses via l'annotation kubernetes.io/change-cause
#     pour qu'ils apparaissent dans "kubectl rollout history".
#     Avec Recreate et un seul replica, l'ancien pod (revision 3) est arrete
#     avant le demarrage du nouveau : a la revision 4, il ne reste donc qu'un
#     seul pod, en CrashLoopBackOff (nginx ne trouve pas son fichier de
#     configuration), et le Deployment est indisponible.
#   - tous les pods ont une readinessProbe httpGet / sur le port 80 : un
#     conteneur qui demarre puis plante immediatement ne devient ainsi jamais
#     Ready, ce qui rend l'etat "indisponible" stable et fiable.
# ============================================================================

rm -f /tmp/.scenario-prep-done

cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours (millennium-falcon, death-star, tie-fighter)..."
TIMEOUT=420
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 3
  ELAPSED=$((ELAPSED + 3))
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
kubectl wait --for=condition=Ready node --all --timeout=120s

# --- 1. millennium-falcon (Recreate, deja en v2) ---
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: millennium-falcon
  annotations:
    kubernetes.io/change-cause: "Initial deployment"
spec:
  replicas: 2
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: millennium-falcon
  template:
    metadata:
      labels:
        app: millennium-falcon
    spec:
      containers:
      - name: millennium-falcon
        image: nginx:alpine
        env:
        - name: APP_RELEASE
          value: "v2"
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
EOF

# --- 2. death-star (1 replica ; deploye, puis mis en pause, puis modifie) ---
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: death-star
  annotations:
    kubernetes.io/change-cause: "Initial deployment"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: death-star
  template:
    metadata:
      labels:
        app: death-star
    spec:
      containers:
      - name: death-star
        image: nginx:alpine
        env:
        - name: APP_RELEASE
          value: "v1"
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
EOF

# La pause ne doit intervenir qu'une fois la revision 1 entierement deployee :
# un Deployment en pause ne cree plus de ReplicaSet.
kubectl rollout status deployment/death-star --timeout=180s

kubectl rollout pause deployment/death-star
kubectl set env deployment/death-star APP_RELEASE=v2
kubectl annotate deployment/death-star kubernetes.io/change-cause="v2 config changes" --overwrite

# --- 3. tie-fighter (1 replica, Recreate, 4 revisions, la derniere defectueuse) ---
# $1 = valeur de APP_RELEASE ; $2 = libelle (change-cause) ; $3 = lignes YAML
# supplementaires pour le conteneur (indentees de 8 espaces), vides par defaut.
apply_tie_fighter() {
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tie-fighter
  annotations:
    kubernetes.io/change-cause: "$2"
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: tie-fighter
  template:
    metadata:
      labels:
        app: tie-fighter
    spec:
      containers:
      - name: tie-fighter
        image: nginx:alpine
$3
        env:
        - name: APP_RELEASE
          value: "$1"
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
EOF
}

apply_tie_fighter "v1" "Initial deployment" ""
kubectl rollout status deployment/tie-fighter --timeout=180s

apply_tie_fighter "v2" "v2 config changes" ""
kubectl rollout status deployment/tie-fighter --timeout=180s

apply_tie_fighter "v3" "v3 rollout" ""
kubectl rollout status deployment/tie-fighter --timeout=180s

# Revision 4 : commande nginx pointant vers un fichier de configuration inexistant.
# On n'attend pas la fin du rollout : il ne se terminera jamais.
apply_tie_fighter "v3" "v3 hotfix" '        command: ["nginx", "-c", "/etc/nginx/hotfix.conf"]'

# On s'assure que millennium-falcon a termine son deploiement.
kubectl rollout status deployment/millennium-falcon --timeout=180s

# --- Attendre que le pod de tie-fighter soit reellement en CrashLoopBackOff ---
# (180 s maximum ; si le statut n'est jamais atteint, la sentinelle n'est pas
# creee et wait-for-prep.sh finit par afficher son message de depassement)
for i in $(seq 1 60); do
  if kubectl get pods -l app=tie-fighter --no-headers 2>/dev/null | grep -q "CrashLoopBackOff"; then
    touch /tmp/.scenario-prep-done
    break
  fi
  sleep 3
done

exit 0
