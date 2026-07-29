# Étape 3 — Installer un add-on réseau de pods (CNI)

Kubernetes ne fournit pas de réseau de pods par défaut : c'est à toi de choisir et d'installer un plugin CNI. On utilise ici **Calico**, un CNI basique mais très répandu en production, installé via son **manifeste unique** (sans opérateur) — la méthode "classique" de déploiement de Calico, toujours documentée et maintenue officiellement.

> Le manifeste utilise par défaut le CIDR `192.168.0.0/16` pour les pods : comme c'est exactement celui passé à `kubeadm init` à l'étape 2, aucune modification n'est nécessaire.

## 1. Installer Calico

`kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/calico.yaml`{{exec}}

Ce manifeste déploie notamment :
- le DaemonSet `calico-node` (un pod par nœud, dans le namespace `kube-system`) ;
- le Deployment `calico-kube-controllers`.

## 2. Suivre le démarrage des pods Calico

`kubectl get pods -n kube-system`{{exec}}

Relance la commande jusqu'à ce que les pods `calico-node-*` et `calico-kube-controllers-*` soient à l'état `Running`.

## 3. Vérifier que le nœud passe à Ready

`kubectl get nodes`{{exec}}

Le nœud doit maintenant afficher `Ready`.
