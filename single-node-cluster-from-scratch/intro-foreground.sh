#!/bin/bash
# ============================================================================
# Script FOREGROUND (visible, occupe le terminal) : attend que le script
# background (intro-background.sh) ait fini de préparer les deux nœuds
# avant de rendre la main à l'élève.
#
# Pourquoi : intro-background.sh est invisible et ne bloque pas la
# progression de l'élève. Sans ce garde-fou, un·e élève rapide peut
# commencer à taper les commandes de l'étape 1 avant que la préparation
# (reset kubeadm, désinstallation kubeadm/kubelet/kubectl, nettoyage APT)
# soit terminée sur controlplane et/ou node01, ce qui provoque des erreurs
# intermittentes du type "E: Unable to locate package".
# ============================================================================

echo "Préparation de l'environnement en cours sur controlplane et node01"
echo "(reset kubeadm, désinstallation de kubeadm/kubelet/kubectl, nettoyage APT)."
echo "Merci de patienter quelques dizaines de secondes, c'est automatique..."
echo ""

TIMEOUT=180
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

echo ""
if [ -f /tmp/.scenario-prep-done ]; then
  echo "C'est prêt ! Tu peux commencer l'étape 1."
else
  echo "La préparation prend plus de temps que prévu (plus de ${TIMEOUT}s)."
  echo "Tu peux commencer, mais si tu obtiens une erreur \"Unable to locate"
  echo "package\" à l'étape 1, attends quelques secondes et relance la commande."
fi
