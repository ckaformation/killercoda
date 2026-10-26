#!/bin/bash
# ============================================================================
# Preparation silencieuse (tout dans le namespace default) :
#   - lien symbolique k -> kubectl
#   - millennium-falcon : 2 replicas, nginx:alpine, APP_RELEASE="v2",
#     strategie Recreate.
#   - death-star : 2 replicas, deployee en APP_RELEASE="v1" (rollout termine),
#     puis MIS EN PAUSE, puis modifie (APP_RELEASE="v2"). Tant que le
#     deployment est en pause, la modification est enregistree dans le spec
#     mais aucun nouveau ReplicaSet (donc aucune nouvelle revision) n'est
#     cree : la revision 2 n'apparait qu'au "rollout resume".
#   - tie-fighter : 2 replicas, 4 revisions creees dans l'ordre :
#       1 = initial deployment    (APP_RELEASE=v1)
#       2 = v2 config changes     (APP_RELEASE=v2)
#       3 = v3 rollout            (APP_RELEASE=v3)
#       4 = v3 hotfix             (APP_RELEASE=v3 + commande nginx invalide)
#     Les libelles sont poses via l'annotation kubernetes.io/change-cause
#     pour qu'ils apparaissent dans "kubectl rollout history".
#     La revision 4 n'est volontairement pas attendue : son pod ne devient
#     jamais Ready (nginx ne trouve pas le fichier de configuration), ce qui
#     donne un pod en CrashLoopBackOff, pendant que les 2 pods de la
#     revision 3 restent en service.
#   - tous les pods ont une readinessProbe httpGet / sur le port 80 : sans
#     elle, un conteneur qui demarre puis plante immediatement pourrait etre
#     brievement compte comme pret, et le rollout de la revision 4 pourrait
#     alors arreter les pods sains.
#   - pas de wait-for-prep.sh (juge peu fiable) : l'etape 1 invite l'eleve a
#     verifier que les 3 Deployments existent.
# ============================================================================

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

# --- 2. death-star (deploye, puis mis en pause, puis modifie) ---
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: death-star
  annotations:
    kubernetes.io/change-cause: "Initial deployment"
spec:
  replicas: 2
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

# --- 3. tie-fighter (4 revisions, la derniere defectueuse) ---
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
  replicas: 2
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

# On s'assure simplement que millennium-falcon a termine son deploiement.
kubectl rollout status deployment/millennium-falcon --timeout=180s

exit 0
