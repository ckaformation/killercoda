# Étape 2 — Corriger le conflit de port

Les deux conteneurs du pod `twin-suns` écoutent tous les deux sur le
port 80 — puisqu'ils partagent le même espace réseau, l'un des deux
ne peut pas démarrer.

Corrige le déploiement pour que les deux conteneurs puissent tourner
normalement :

- remplace l'image du conteneur `httpd` par `traefik/whoami:v1.11`
- donne-lui l'argument `--port 8080`

<details>
<summary>💡 Indice</summary>

Tu peux éditer un déploiement existant directement avec `kubectl
edit`.

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl edit deployment twin-suns -n tatooine
```{{exec}}

Dans le conteneur `httpd`, remplace :

```yaml
image: httpd:2-alpine
```

par :

```yaml
image: traefik/whoami:v1.11
args:
- --port
- "8080"
```

Enregistre et quitte. Vérifie :

```
kubectl get pods -n tatooine
```{{exec}}

Les deux conteneurs du pod doivent passer à `2/2 Running`.

</details>
