# Étape 2 — Ajouter une livenessProbe exec

La `livenessProbe` indique si le conteneur est **vivant**. Si elle échoue, le kubelet considère que l'application est bloquée : il **tue le conteneur et le redémarre**.

Ajoute au conteneur de `echo-base` une `livenessProbe` qui :

- exécute la commande `stat /tmp/life-signs` dans le conteneur ;
- commence **10 secondes** après le démarrage du conteneur (`initialDelaySeconds: 10`) ;
- s'exécute **toutes les 7 secondes** (`periodSeconds: 7`) ;
- considère le conteneur comme mort dès le **premier échec** (`failureThreshold: 1`).

## 1. Tester la commande à la main

C'est exactement ce que le kubelet va lancer dans le conteneur :

`kubectl -n hoth exec deploy/echo-base -- stat /tmp/life-signs`{{exec}}

La commande affiche les informations du fichier. Regarde son code de sortie :

`echo $?`{{exec}}

Tu dois voir `0`. Une probe `exec` réussit si la commande renvoie `0`, et échoue sinon.

## 2. Ajouter la livenessProbe

`vi /root/echo-base.yaml`{{exec}}

Ajoute ce bloc à la fin du fichier, sous la `readinessProbe` (même indentation que `readinessProbe:`, soit 8 espaces) :

```yaml
        livenessProbe:
          exec:
            command:
            - stat
            - /tmp/life-signs
          initialDelaySeconds: 10
          periodSeconds: 7
          failureThreshold: 1
```

## 3. Appliquer

`kubectl apply -f /root/echo-base.yaml`{{exec}}

`kubectl -n hoth rollout status deployment/echo-base`{{exec}}

## 4. Observer

`kubectl -n hoth get pods`{{exec}}

Un nouveau pod a remplacé le précédent. Sa colonne `RESTARTS` est à `0` : la commande réussit à chaque passage, le kubelet ne fait rien.

`kubectl -n hoth describe pod -l app=echo-base | grep -E 'Liveness|Readiness'`{{exec}}

Les deux probes sont en place. Pour la liveness : `exec [stat /tmp/life-signs]`, `delay=10s`, `period=7s` et `#failure=1`.

> `failureThreshold: 1` rend la probe très réactive, mais aussi très sensible : un seul échec ponctuel (par exemple une commande qui dépasse `timeoutSeconds`, 1 seconde par défaut) suffit à redémarrer le conteneur. La valeur par défaut est `3`.
