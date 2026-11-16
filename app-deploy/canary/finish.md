# Bravo !

Tu as fait passer tout le trafic d'une version à l'autre, par paliers, uniquement en jouant sur les réplicas :

1. **25 %** : création de `x-wing-canary` (1 réplica) à partir du manifeste de `x-wing-current`, ramené à 3 réplicas.
2. **50 %** : 2 réplicas de chaque côté.
3. **100 %** : 4 réplicas canary, `x-wing-current` conservé à 0 réplica.

## Points clés à retenir

- Le Service vise un label **commun** aux deux versions (`app=x-wing`) : il répartit les requêtes entre tous les pods prêts, quelle que soit leur version.
- Chaque version a son propre Deployment, avec un label qui la distingue (`track`) **dans son selector** : les deux Deployments ne gèrent jamais les mêmes pods.
- La part de trafic de la canary vaut à peu près `pods canary / pods au total`. La répartition est aléatoire : les chiffres varient d'un essai à l'autre.
- La finesse dépend du nombre de pods : 25 % demande 4 pods au total, 10 % en demanderait 10. Pour un pourcentage indépendant du nombre de pods, il faut des poids de routage (par exemple une `HTTPRoute` de la Gateway API).
- Augmenter la canary **avant** de réduire l'ancienne version garde la capacité de l'application.
- Garder l'ancien Deployment à 0 réplica permet un retour arrière rapide avec `kubectl scale`.

## Pour aller plus loin

- Tutoriel officiel sur le déploiement canary : https://kubernetes.io/docs/tutorials/stateless-application/canary-deployment/
- Services : https://kubernetes.io/docs/concepts/services-networking/service/
- Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- `kubectl scale` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/
