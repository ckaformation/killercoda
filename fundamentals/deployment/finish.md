# Bravo !

Tu as suivi la vie d'un Deployment :

1. **Création** : `k create deployment snowspeeder` a produit un Deployment, un ReplicaSet et 3 pods. Les noms trahissent la filiation, et les labels `app` et `pod-template-hash` relient pods et ReplicaSet via le selector.
2. **Scaling et auto-réparation** : en passant à 5 réplicas, tu as modifié l'état désiré, pas le pod template : un seul ReplicaSet, 5 pods. Quand tu as supprimé un pod, le ReplicaSet a créé son remplaçant pour revenir à 5.
3. **Mise à jour** : `k set image` a modifié le pod template. Le Deployment a créé un **nouveau** ReplicaSet, y a déplacé progressivement les pods, et a gardé l'ancien à 0 réplica.

## Ce qu'il faut retenir

- Le Deployment décrit l'état désiré ; le ReplicaSet maintient le nombre de pods ; les pods font tourner les containers.
- Un contrôleur gère les pods dont les labels correspondent à son selector. Le label `pod-template-hash` distingue les pods de chaque ReplicaSet d'un même Deployment.
- Le scaling ne crée pas de ReplicaSet. Seule une modification du pod template (image, variables d'environnement...) en crée un.
- Contrairement à un pod « nu », un pod géré par un Deployment est recréé s'il est supprimé.
- L'ancien ReplicaSet est conservé à 0 réplica : c'est ce qui rend possible un retour en arrière (`k rollout undo`), que tu pratiqueras dans les scénarios sur les rollouts.

## Pour aller plus loin

- Documentation officielle des Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
