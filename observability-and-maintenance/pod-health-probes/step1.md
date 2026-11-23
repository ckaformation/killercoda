# Étape 1 — Ajouter une readinessProbe HTTP

La `readinessProbe` indique si le conteneur est **prêt à recevoir du trafic**. Tant qu'elle échoue, le pod n'est pas `Ready` et les Services ne lui envoient pas de requêtes.

Ajoute au conteneur de `echo-base` une `readinessProbe` qui :

- fait un **HTTP GET** sur le path `/healthz` (port 80) ;
- commence **5 secondes** après le démarrage du conteneur (`initialDelaySeconds: 5`) ;
- s'exécute **toutes les 10 secondes** (`periodSeconds: 10`).

## 1. Observer l'état actuel

`kubectl -n hoth get pods`{{exec}}

Le pod doit être `Running` et `1/1`. Si ce n'est pas encore le cas, attends quelques secondes et relance la commande.

`cat /root/echo-base.yaml`{{exec}}

Le conteneur n'a aucune probe. Vérifie que la page `/healthz` répond bien depuis le conteneur :

`kubectl -n hoth exec deploy/echo-base -- wget -qO- http://127.0.0.1/healthz`{{exec}}

Tu dois voir `ok`. C'est cette page que le kubelet va interroger.

## 2. Ajouter la readinessProbe

Pour retrouver les champs disponibles (utile le jour de l'examen) :

`kubectl explain pod.spec.containers.readinessProbe`{{exec}}

Ouvre le manifeste :

`vi /root/echo-base.yaml`{{exec}}

Ajoute ce bloc à la fin du fichier, sous `ports` (même indentation que `ports:`, soit 8 espaces) :

```yaml
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

## 3. Appliquer et observer

`kubectl apply -f /root/echo-base.yaml`{{exec}}

Si l'API refuse le fichier, relis l'indentation.

Les probes font partie du *pod template* : les modifier déclenche un rollout, donc un nouveau pod. Observe-le :

`kubectl -n hoth get pods -w`{{exec}}

- Le nouveau pod est d'abord `Running` mais `0/1` : le conteneur tourne, mais la readinessProbe n'a pas encore réussi.
- Quelques secondes plus tard, il passe à `1/1`.
- C'est seulement à ce moment que l'ancien pod est arrêté : le rollout attend que le nouveau pod soit prêt.

Quitte avec `Ctrl+C`.

`kubectl -n hoth describe pod -l app=echo-base | grep Readiness`{{exec}}

Tu retrouves tes valeurs (`delay=5s`, `period=10s`), ainsi que des valeurs par défaut que tu n'as pas écrites : `timeout=1s`, `#success=1` et `#failure=3` (il faut 3 échecs consécutifs pour que le conteneur soit considéré comme non prêt).
