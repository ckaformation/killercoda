#!/bin/bash
# ============================================================================
# Preparation silencieuse (volontairement minimale) :
#   - dossier /root/holocron avec message.txt : le contenu que l'eleve va
#     empaqueter dans l'image (ASCII uniquement, pour eviter tout souci
#     d'encodage dans l'image ou dans les comparaisons des verify.sh)
#   - Docker : la presence par defaut de Docker sur le backend "ubuntu" de
#     Killercoda n'est pas confirmee de facon certaine (indices indirects
#     seulement). Installation defensive depuis les depots Ubuntu uniquement
#     si la commande "docker" est absente, sur le meme principe que pour
#     crictl dans les scenarios precedents.
#   - pas de wait-for-prep.sh : la preparation est quasi instantanee dans le
#     cas nominal (Docker deja present), et ce mecanisme a ete juge peu
#     fiable dans les scenarios recents.
# ============================================================================

mkdir -p /root/holocron

cat > /root/holocron/message.txt << 'MSGEOF'
Transmission interceptee : les plans de l'Etoile de la Mort sont en route.
MSGEOF

if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
fi

systemctl start docker 2>/dev/null || true

exit 0
