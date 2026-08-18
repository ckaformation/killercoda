#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - création du namespace "jedi" ;
#   - mise à disposition de "k" comme raccourci pour "kubectl", via un lien
#     symbolique dans /usr/local/bin plutôt qu'un alias bash (fonctionne
#     immédiatement, y compris dans un terminal déjà ouvert, sans dépendre
#     du rechargement de ~/.bashrc).
#
# Cette étape est rapide (pas de reset/réinstallation lourde comme dans les
# autres scénarios), donc pas de mécanisme d'attente nécessaire ici.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create namespace jedi

exit 0
