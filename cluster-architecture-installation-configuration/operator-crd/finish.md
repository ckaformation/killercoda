# Bravo !

Tu viens d'installer un opérateur Kubernetes et de créer la CRD qu'il interprète :

1. **Installation de l'opérateur** : `ServiceAccount` dédié, `ClusterRole` réutilisé via trois `RoleBinding` (un par namespace cible), et un `Deployment` qui réconcilie en boucle.
2. **CRD** : un nouveau type de ressource (`Greeting`, groupe `training.example.com`), avec un schéma minimal (`spec.message`).
3. **Ressource personnalisée** : une instance de `Greeting`, dans `luke`, réconciliée par l'opérateur en une `ConfigMap`.

## Points clés à retenir

- Le pattern opérateur : un contrôleur qui **surveille** un type de ressource (souvent une CRD) et **réagit** en créant/mettant à jour d'autres objets, jusqu'à ce que l'état réel corresponde à l'état désiré. Cet opérateur simplifié utilise du polling (interroger l'API à intervalle régulier) ; un vrai opérateur (via client-go, Operator SDK, Kubebuilder…) utilise plutôt un mécanisme de *watch* événementiel, plus réactif et moins coûteux en appels API — mais le principe de fond est identique.
- Scoper un opérateur à un sous-ensemble précis de namespaces suit exactement la même logique RBAC qu'un utilisateur humain (`rbac-luke-jedi`) : un `ClusterRole` réutilisé via plusieurs `RoleBinding`, jamais un `ClusterRoleBinding` (qui s'appliquerait à tout le cluster).
- Une CRD `apiextensions.k8s.io/v1` exige un schéma OpenAPI v3 structurel (`spec.versions[].schema.openAPIV3Schema`) — ce n'était pas obligatoire avec l'ancienne version `v1beta1`, aujourd'hui retirée.
- La défense est en profondeur ici : même si le script de l'opérateur avait un bug et tentait d'agir sur un namespace hors de `luke`/`ben`/`leia`, le RBAC le lui interdirait quand même — la portée du code et la portée des droits se renforcent mutuellement.

## Pour aller plus loin

- Extending the Kubernetes API : https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- CustomResourceDefinition : https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
- Operator pattern : https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
