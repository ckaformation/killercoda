# Étape 3 — Monter un ConfigMap additionnel

## 1. Créer le ConfigMap

`kubectl create configmap death-star-plans-config --from-literal=briefing.txt="Plans du Death Star en cours d'analyse."`{{exec}}

`k get configmap death-star-plans-config -o yaml`{{exec}}

## 2. Modifier le Deployment pour le monter

`kubectl edit deployment death-star-plans`{{exec}}

Deux ajouts à faire :

1. Dans `spec.template.spec.volumes`, un nouveau volume :
```yaml
- name: briefing
  configMap:
    name: death-star-plans-config
```

2. Dans `spec.template.spec.containers[0].volumeMounts` (le conteneur `nginx`), un nouveau montage :
```yaml
- name: briefing
  mountPath: /etc/briefing
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`. L'édition du pod template déclenche automatiquement un nouveau rollout — pas besoin de `rollout restart` cette fois.

## 3. Vérifier

`kubectl rollout status deployment/death-star-plans`{{exec}}

`POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}') && kubectl exec "$POD" -c nginx -- cat /etc/briefing/briefing.txt`{{exec}}

Doit afficher le contenu du ConfigMap.
