# Troubleshooting control plane

Deux composants du cluster posent problème :

- `kube-controller-manager`, sur `controlplane`, ne redémarre pas
  après une mise à jour de sa configuration.
- `kubelet`, sur `node01`, ne démarre pas du tout.

Applique la méthode de diagnostic déjà vue (`crictl`, `journalctl -u
kubelet`) pour comprendre et corriger chaque situation.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
