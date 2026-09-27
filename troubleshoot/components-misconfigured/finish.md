# Bravo !

Tu as :

- Diagnostiqué un `kube-controller-manager` qui ne redémarrait pas
  après une mise à jour de son manifest, avec la même méthode que
  pour l'apiserver.
- Diagnostiqué un `kubelet` en échec de démarrage sur un second nœud,
  via `journalctl -u kubelet` — la seule source disponible quand
  kubelet lui-même ne tourne pas.
- Constaté, à nouveau, qu'une cascade d'erreurs peut en cacher une
  autre : corriger la première a révélé la seconde.

## Pour aller plus loin

- `/var/lib/kubelet/kubeadm-flags.env` et `/var/lib/kubelet/config.yaml`
  jouent des rôles différents : le premier fournit les arguments de
  ligne de commande, le second une configuration structurée. Une
  erreur dans l'un comme dans l'autre empêche kubelet de démarrer,
  mais avec des symptômes différents dans les logs.
- Que se passe-t-il pour les pods qui tournaient sur `node01` pendant
  que son kubelet était en échec ? Regarde leur statut avant et après
  la correction.
