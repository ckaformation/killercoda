#!/bin/bash
# ============================================================================
# Preparation silencieuse :
#   - /root/wait-for-prep.sh : depose des le debut (installation de podman et
#     telechargement de registry:2 : bien plus de 20 s). Il attend le fichier
#     sentinelle /tmp/.scenario-prep-done, cree a la toute fin de ce script,
#     puis affiche l'etat de podman et de la registry.
#   - lien symbolique k -> kubectl
#   - podman installe depuis les depots Ubuntu s'il est absent
#   - /etc/containers/registries.conf.d/99-scenario.conf :
#       * nom court "bash" (FROM bash) resolu sur docker.io
#       * registry localhost:5000 declaree "insecure" (HTTP, sans TLS)
#   - registry locale : conteneur podman "jedi-archives" (docker.io/library/
#     registry:2), sur le reseau de l'hote : ecoute sur localhost:5000, sans
#     NAT, donc joignable aussi par containerd (kubelet) sur le meme noeud
#   - attente que l'API et le noeud soient prets
# Rien n'est configure cote containerd : il contacte deja localhost en HTTP
# par defaut (cf. README, Limites connues).
# ============================================================================

rm -f /tmp/.scenario-prep-done

cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours (podman et registry locale)..."
TIMEOUT=420
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 3
  ELAPSED=$((ELAPSED + 3))
done
if [ ! -f /tmp/.scenario-prep-done ]; then
  echo "La preparation prend plus de temps que prevu. Patiente encore un peu, puis relance /root/wait-for-prep.sh."
  exit 1
fi
OK=1
if command -v podman >/dev/null 2>&1; then
  echo "OK : $(podman --version)"
else
  echo "ERREUR : podman est introuvable."
  OK=0
fi
if curl -s --max-time 5 http://localhost:5000/v2/ >/dev/null 2>&1; then
  echo "OK : la registry repond sur localhost:5000"
else
  echo "ERREUR : la registry ne repond pas sur localhost:5000."
  OK=0
fi
[ "$OK" = "1" ] && echo "C'est pret ! Tu peux continuer."
WAITEOF
chmod +x /root/wait-for-prep.sh

ln -sf "$(which kubectl)" /usr/local/bin/k

# --- podman ---
if ! command -v podman >/dev/null 2>&1; then
  apt-get update || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y podman || true
fi

mkdir -p /etc/containers/registries.conf.d
cat > /etc/containers/registries.conf.d/99-scenario.conf << 'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
location = "localhost:5000"
insecure = true
EOF

# --- registry locale (conteneur podman sur le reseau de l'hote) ---
if ! podman container exists jedi-archives 2>/dev/null; then
  podman run -d --name jedi-archives --network host docker.io/library/registry:2 || true
fi
podman start jedi-archives >/dev/null 2>&1 || true
for i in $(seq 1 30); do
  curl -s --max-time 2 http://localhost:5000/v2/ >/dev/null 2>&1 && break
  sleep 2
done

# --- Attendre l'API et le noeud ---
for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

touch /tmp/.scenario-prep-done
exit 0
