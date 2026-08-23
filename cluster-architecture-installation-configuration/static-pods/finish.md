# Bravo !

Tu viens de manipuler des static pods de bout en bout :

1. **Création** d'un static pod (`static-web`, basé sur `nginx`) en écrivant directement un manifeste dans le `staticPodPath` du kubelet, sans passer par l'API server ni le scheduler.
2. **Vérification à deux niveaux** : le pod miroir côté `kubectl` (vue API), et le conteneur réel côté `crictl` (vue runtime, directe, indépendante de l'API server).
3. **Changement du `staticPodPath`**, en relocalisant *tous* les manifestes existants (control-plane inclus) avant de redémarrer le kubelet — pas seulement le tien.

## Points clés à retenir

- Un static pod est géré **localement** par le kubelet, à partir d'un fichier manifeste : pas de scheduler, pas d'objet Deployment/ReplicaSet, pas de contrôle direct possible via `kubectl delete` (le kubelet le recrée aussitôt tant que le fichier existe).
- Le pod miroir créé dans l'API porte le suffixe du nom du nœud (`static-web-<nœud>`) — c'est une simple fenêtre de visibilité, pas l'objet qui pilote réellement le pod.
- `crictl` interroge directement le runtime de conteneurs (`containerd`), sans dépendre de l'API server — un outil de secours précieux, y compris pour diagnostiquer l'API server lui-même, puisque c'est aussi un static pod.
- `staticPodPath` est un réglage **global** du kubelet : le changer affecte tout ce qu'il gère comme static pods, y compris (potentiellement) le control-plane. C'est pour ça que cet exercice s'est déroulé sur `node01` plutôt que sur `controlplane` : sur un vrai nœud control-plane, toute relocalisation doit copier/déplacer **tous** les manifestes existants **avant** de redémarrer le kubelet, jamais après.

## Pour aller plus loin

- Documentation officielle : https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/
- Debugging avec crictl : https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/
