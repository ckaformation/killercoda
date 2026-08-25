# Étape 2 — Déclencher une préemption par manque de mémoire

## Contexte

Le nœud est volontairement chargé : `star-destroyer` (`level2`, 1Gi) tourne déjà, et un pod technique nommé `filler` occupe le reste de la marge disponible, pour qu'il ne reste qu'un peu plus de 1Gi de libre au total — pas assez pour un second pod à 1Gi en plus de `star-destroyer`.

## 1. Observer l'état actuel

`k get pods -n empire -o wide`{{exec}}

`k describe node | grep -A5 "Allocated resources"`{{exec}}

## 2. Créer un pod de priorité supérieure

`vi /root/flagship.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: flagship
  namespace: empire
spec:
  priorityClassName: level3
  containers:
    - name: nginx
      image: nginx:alpine
      resources:
        requests:
          memory: "1Gi"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl apply -f /root/flagship.yaml`{{exec}}

## 3. Observer

`k get pods -n empire -o wide`{{exec}}

`star-destroyer` doit avoir disparu, et `flagship` doit être `Running` à sa place. Faute de mémoire disponible pour les deux, Kubernetes a **préempté** `star-destroyer` (`level2`, priorité strictement inférieure à `level3`) pour libérer la place nécessaire à `flagship`.

`k get events -n empire --sort-by='.lastTimestamp' | grep -i preempt`{{exec}}

Les événements confirment la préemption et sa raison.
