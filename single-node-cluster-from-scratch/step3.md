# Étape 3 — Installer un add-on réseau de pods (CNI)

Kubernetes ne fournit pas de réseau de pods par défaut : c'est à toi de choisir et d'installer un plugin CNI. On utilise ici **Flannel**, avec le manifeste officiel du projet.

## 1. Installer Flannel

`kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml`{{exec}}

## 2. Suivre le démarrage des pods Flannel

`kubectl get pods -n kube-flannel`{{exec}}

Relance la commande jusqu'à ce que les pods `kube-flannel-ds-*` soient à l'état `Running`.

## 3. Vérifier que le nœud passe à Ready

`kubectl get nodes`{{exec}}

Le nœud doit maintenant afficher `Ready`.
