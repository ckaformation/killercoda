# Troubleshooting kube-apiserver — 3 erreurs cumulées

Le scénario précédent t'a fait découvrir une méthode de diagnostic
pour `kube-apiserver` sans dépendre de `kubectl` : `crictl`,
`/var/log`, `journalctl -u kubelet`.

Cette fois, applique cette méthode par toi-même.

Une sauvegarde du manifest sain existe à `/root/kube-apiserver-backup.yaml`,
au cas où tu voudrais comparer — mais l'objectif est de trouver et
corriger chaque erreur toi-même, pas de tout restaurer d'un coup.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
