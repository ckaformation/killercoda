# Étape 2 — Déployer via un Deployment et le scaler

## 1. Écrire le Deployment

On garde une variable d'environnement `SQUADRON_VERSION` dans le pod template : elle nous servira à l'étape 3 pour déclencher de nouvelles révisions, sans dépendre d'un tag d'image précis.

`vi /root/x-wing-fleet.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-wing-fleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: x-wing-fleet
  template:
    metadata:
      labels:
        app: x-wing-fleet
    spec:
      containers:
        - name: x-wing
          image: nginx:alpine
          env:
            - name: SQUADRON_VERSION
              value: "v1"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Déployer

`kubectl apply -f /root/x-wing-fleet.yaml`{{exec}}

`k get pods -l app=x-wing-fleet`{{exec}}

Attends que le pod soit `Running` avant de continuer.

## 3. Scaler à 3 réplicas avec kubectl edit

`kubectl edit deployment x-wing-fleet`{{exec}}

Change `replicas: 1` en `replicas: 3`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 4. Vérifier

`k get pods -l app=x-wing-fleet`{{exec}}

Tu dois voir 3 pods. Vérifie aussi qu'un simple scaling ne crée **pas** de nouvelle révision :

`k get replicaset -l app=x-wing-fleet`{{exec}}

Un seul ReplicaSet doit apparaître : scaler un Deployment ne touche pas au pod template, donc pas de nouvelle révision. On y reviendra concrètement à l'étape suivante.
