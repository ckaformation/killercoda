#!/bin/bash
# ============================================================================
# Preparation silencieuse minimale : ce scenario ne necessite rien de plus
# qu'un cluster fonctionnel — le Deployment est cree par l'eleve a l'etape 1.
#   - lien symbolique k -> kubectl
#   - attente que le noeud soit Ready (au cas ou l'eleve irait tres vite)
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

exit 0
