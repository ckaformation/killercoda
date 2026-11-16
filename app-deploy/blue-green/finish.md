# Bravo !

Tu as mis en œuvre un déploiement blue/green avec un simple Service :

1. **Bascule** : le Service NodePort `lightsaber` est passé de blue à green en changeant son selector.
2. **Rollback** : le retour sur blue a été immédiat, sans recréer un seul pod.
3. **Test interne** : un Service ClusterIP `lightsaber-green` permet de tester green depuis le cluster, pendant que le trafic public reste sur blue.

## Points clés à retenir

- Un Service envoie le trafic vers les pods prêts dont les labels correspondent à **tous** les labels de son selector.
- En blue/green, chaque version a son propre Deployment et un label qui la distingue (ici `version`). Le selector de chaque Deployment doit inclure ce label pour que les deux Deployments ne gèrent pas les mêmes pods.
- Basculer ou revenir en arrière = modifier le selector du Service (`kubectl patch` ou `kubectl edit`). Aucun rollout n'est déclenché.
- Le coût : les deux versions tournent en même temps, donc deux fois plus de ressources pendant la transition.
- `kubectl expose deployment <nom> --port=<port>` crée un Service `ClusterIP` par défaut, avec le selector du Deployment.
- Les endpoints d'un Service se consultent avec `kubectl get endpointslices -l kubernetes.io/service-name=<service>`.
- Un Service ClusterIP n'est joignable que depuis le cluster : un pod temporaire (`kubectl run ... --rm -it --restart=Never`) suffit pour le tester.

## Pour aller plus loin

- Services : https://kubernetes.io/docs/concepts/services-networking/service/
- Labels et selectors : https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- EndpointSlices : https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
- `kubectl expose` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/
- `kubectl patch` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
