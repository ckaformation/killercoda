# Étape 1 — Créer le DaemonSet avec un hostPath

## 1. Écrire le DaemonSet

`vi /root/probe-droid.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: probe-droid
  namespace: hoth
spec:
  selector:
    matchLabels:
      app: probe-droid
  template:
    metadata:
      labels:
        app: probe-droid
    spec:
      containers:
        - name: probe-droid
          image: bash:5
          command:
            - bash
            - -c
            - |
              while true; do
                echo "Aucune activite rebelle detectee sur ce noeud." > /data/scan-report.txt
                sleep 5
              done
          volumeMounts:
            - name: scan-log
              mountPath: /data
      volumes:
        - name: scan-log
          hostPath:
            path: /var/log/probe-droid
            type: DirectoryOrCreate
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

> Le conteneur réécrit son fichier toutes les 5 secondes plutôt qu'une seule fois au démarrage : ce sera important à l'étape 2, pour distinguer "le pod ne tourne plus ici" de "le pod tourne mais n'a pas retouché ce fichier depuis un moment".

## 2. Déployer

`kubectl apply -f /root/probe-droid.yaml`{{exec}}

## 3. Vérifier

`k get daemonset -n hoth`{{exec}}

`k get pods -n hoth -o wide`{{exec}}

Un pod doit apparaître sur `controlplane` **et** sur `node01` : sans `nodeSelector`, un DaemonSet cible tous les nœuds éligibles.

## 4. Vérifier le fichier sur controlplane

`cat /var/log/probe-droid/scan-report.txt`{{exec}}

## 5. Vérifier le fichier sur node01

Bascule sur l'onglet **`node01`** :

`cat /var/log/probe-droid/scan-report.txt`{{exec}}

Le même contenu doit apparaître : chaque pod écrit sur le disque **local** de son propre nœud, pas dans un espace partagé.
