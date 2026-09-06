# Étape 3 — apiVersion corrompue

Modifie le manifest pour remplacer la clé `apiVersion` par une clé et
une valeur bidon :

```
sed -i 's#^apiVersion: v1#holocron: order66#' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

À toi d'investiguer, avec les outils utilisés jusqu'ici, pour
comprendre ce qui se passe. Aucune indication supplémentaire cette
fois.

## Restaurer le manifest

Une fois l'erreur identifiée :

```
cp /root/kube-apiserver-backup.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

```
watch crictl ps
```{{exec}}
