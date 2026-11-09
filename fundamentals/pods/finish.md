# Bravo !

Tu as suivi la vie d'un pod de bout en bout :

1. **Création** : `k run bb-8 --image=nginx:alpine` a créé un pod, que tu as inspecté avec `k describe` et `k logs`.
2. **Placement** : le scheduler a placé le pod sur `node01`, parce que le taint `node-role.kubernetes.io/control-plane:NoSchedule` repousse les pods ordinaires hors de `controlplane`.
3. **Runtime** : en `ssh` sur `node01`, `crictl` t'a montré le pod (sa sandbox) et son container, avec les mêmes logs que `k logs`.
4. **Container supprimé** : après `crictl rm -f`, le kubelet a recréé un container (nouvel identifiant) dans le même pod.
5. **Pod supprimé** : après `k delete pod`, le pod n'est pas revenu, car aucun contrôleur n'en avait la charge.

## La chaîne de responsabilités

| Acteur | Rôle |
|---|---|
| `kubectl` / API server | Enregistre l'objet Pod |
| Scheduler | Choisit le node (en tenant compte des taints) |
| Kubelet | Lance et surveille les containers du pod sur le node, et les relance s'ils disparaissent |
| containerd | Exécute réellement les containers (c'est lui que `crictl` interroge) |
| Contrôleur (Deployment...) | Recrée un pod supprimé : c'est lui qui manquait ici |

## Pour aller plus loin

- Pour voir le manifeste que `k run` génère, sans créer le pod : `k run bb-8 --image=nginx:alpine --dry-run=client -o yaml`.
- Documentation officielle des Pods : https://kubernetes.io/docs/concepts/workloads/pods/
