# Bravo !

Tu viens de diagnostiquer et corriger un problème RBAC classique sur un ServiceAccount utilisé par un CronJob, puis d'étendre ces droits à un second ServiceAccount :

1. **Diagnostic** : lecture des logs du Job en échec et confirmation via `kubectl auth can-i --as=system:serviceaccount:<namespace>:<nom>`.
2. **Correction** : un `Role` scopé au namespace `ops` (`get`, `list`, `delete` sur `pods`), lié au ServiceAccount `leon` via un `RoleBinding`.
3. **Vérification** : observation du nettoyage automatique par le CronJob, une fois les droits corrigés.
4. **Clonage** : export de `leon` en YAML, édition avec `vi` (nouveau nom, suppression des champs générés par le serveur, ajout de `automountServiceAccountToken: false`), puis `kubectl apply`.
5. **Extension des droits** : ajout de `leon-2` comme second sujet du `RoleBinding` existant, via `kubectl edit`, plutôt que de dupliquer un `RoleBinding`.

## Points clés à retenir

- Un Pod dont le `serviceAccountName` référence un ServiceAccount inexistant ne démarre pas du tout (erreur d'admission). Un ServiceAccount qui existe mais sans RBAC associé, en revanche, laisse le pod démarrer normalement : l'échec ne survient qu'au moment de l'appel à l'API Kubernetes (ici, lors du `kubectl delete pods` interne au conteneur), sous forme d'une erreur `Forbidden`.
- Un ServiceAccount s'usurpe avec `--as=system:serviceaccount:<namespace>:<nom>`, contrairement à un utilisateur externe qui s'usurpe avec `--as=<nom>`.
- Un `RoleBinding` peut lier **plusieurs sujets** (utilisateurs, groupes, ServiceAccounts) à un seul `Role` : pas besoin de dupliquer un `RoleBinding` pour chaque nouveau sujet qui doit avoir les mêmes droits.
- Cloner un objet Kubernetes par export/édition/apply impose de retirer les champs gérés par le serveur (`resourceVersion`, `uid`, `creationTimestamp`) et de changer son nom, sous peine d'erreur ou de conflit avec l'objet d'origine.

## Pour aller plus loin

- Documentation officielle RBAC : https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- ServiceAccounts : https://kubernetes.io/docs/concepts/security/service-accounts/
- CronJob : https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
