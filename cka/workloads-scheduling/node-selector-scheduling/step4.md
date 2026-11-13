# Étape 4 — Arrêter le kube-scheduler et scheduler sans lui

## 1. Arrêter le kube-scheduler

Comme les autres composants du control-plane, `kube-scheduler` est un static pod : le retirer de son dossier surveillé suffit à l'arrêter.

`k get pods -n kube-system -l component=kube-scheduler`{{exec}}

`mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/`{{exec}}

`k get pods -n kube-system -l component=kube-scheduler`{{exec}}

Le pod doit disparaître après quelques secondes. Contrairement à `kube-apiserver` ou `etcd`, arrêter uniquement le `kube-scheduler` n'affecte ni `kubectl`, ni les pods déjà en cours d'exécution — seuls les **nouveaux** pods sans nœud assigné en pâtiraient, faute de composant pour choisir un nœud à leur place.

## 2. Créer un pod avec nodeName explicite

`vi /root/vader.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vader
spec:
  nodeName: node01
  containers:
    - name: nginx
      image: nginx:alpine
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl apply -f /root/vader.yaml`{{exec}}

## 3. Vérifier

`k get pod vader -o wide`{{exec}}

Le pod doit passer à `Running`, sur `node01` — sans qu'aucun scheduler n'ait été impliqué. `spec.nodeName` court-circuite entièrement l'étape de décision : le kubelet de `node01` surveille directement les pods qui lui sont assignés, peu importe comment ils l'ont été. Le rôle du `kube-scheduler` se limite exactement à ça : choisir la valeur de `nodeName` pour les pods qui ne l'ont pas déjà.

> Pense à remettre `kube-scheduler.yaml` en place (`mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/`) si tu comptes continuer à utiliser ce cluster pour autre chose après ce scénario.
