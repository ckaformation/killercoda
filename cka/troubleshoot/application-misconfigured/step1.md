# Étape 1 — jedi-temple

Le déploiement `archive-terminal` (namespace `jedi-temple`) ne
fonctionne pas correctement. Diagnostique et corrige le problème.

```
kubectl get pods -n jedi-temple
```{{exec}}

<details>
<summary>💡 Indice</summary>

`kubectl describe pod` te donnera des informations sur l'état du
conteneur.

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl describe pod -n jedi-temple -l app=archive-terminal
```{{exec}}

Le conteneur référence un `ConfigMap` qui n'existe pas
(`archive-config-old`), alors que le vrai s'appelle `archive-config`.

```
kubectl edit deployment archive-terminal -n jedi-temple
```{{exec}}

Corrige le nom du `ConfigMap` référencé (`archive-config-old` →
`archive-config`), enregistre et quitte (`:wq`). Vérifie :

```
kubectl get pods -n jedi-temple
```{{exec}}

</details>
