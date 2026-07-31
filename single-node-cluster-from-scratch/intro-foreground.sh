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
#
# Mécanisme : un tube nommé (FIFO), pas une boucle de polling avec sleep.
# Une seule commande bloquante ("cat" sur la FIFO) : rien ne s'affiche
# pendant l'attente, contrairement à une boucle "while/sleep" qui
# réaffiche des lignes en continu.
# ============================================================================

echo "Préparation de l'environnement en cours..."

mkfifo /tmp/.scenario-prep-fifo 2>/dev/null

if timeout 180 cat /tmp/.scenario-prep-fifo >/dev/null 2>&1; then
  echo "C'est prêt ! Tu peux commencer l'étape 1."
else
  echo "C'est prêt (ou presque) ! Si tu obtiens une erreur \"Unable to locate package\" à l'étape 1, attends quelques secondes et relance la commande."
fi

rm -f /tmp/.scenario-prep-fifo 2>/dev/null
