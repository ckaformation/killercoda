# Étape 2 — Sidecar natif et volume emptyDir

Un init container s'arrête avant le démarrage de l'application. Un **sidecar natif** démarre lui aussi avant elle, mais **reste en marche** pendant toute la vie du pod. C'est un init container qui porte `restartPolicy: Always`.

## 1. Le champ qui fait un sidecar

`k explain deploy.spec.template.spec.initContainers.restartPolicy`{{exec}}

Pour un init container, `Always` est la seule valeur acceptée.

## 2. Ajouter le volume et le sidecar

`vi /root/x-wing.yaml`{{exec}}

Complète le `spec` du template avec les trois blocs marqués :

```yaml
    spec:
      terminationGracePeriodSeconds: 1
      volumes:                 # à ajouter (bloc)
      - name: html
        emptyDir: {}
      initContainers:          # à ajouter (bloc)
      - name: r2-d2
        image: busybox
        restartPolicy: Always
        command: ["sh", "-c", "while true; do echo $RANDOM > /usr/share/nginx/html/index.html; sleep 1; done"]
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:          # à ajouter (bloc)
        - name: html
          mountPath: /usr/share/nginx/html
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`$RANDOM` donne un nombre aléatoire à chaque lecture. C'est `sh` qui l'interprète : Kubernetes ne remplace que la syntaxe `$(VARIABLE)`.

## 3. Appliquer et tester

`k apply -f /root/x-wing.yaml`{{exec}}

`k rollout status deploy x-wing`{{exec}}

`k get pods -l app=x-wing`{{exec}}

La colonne `READY` affiche `2/2` : contrairement à l'init container de l'étape 1, le sidecar tourne et il est compté. S'il reste un pod `Terminating`, attends qu'il disparaisse.

`IP=$(k get pod -l app=x-wing -o jsonpath='{.items[0].status.podIP}')`{{exec}}

```
for i in 1 2 3 4 5; do curl -s $IP; sleep 1; done
```{{exec}}

Le nombre change à chaque appel : `r2-d2` réécrit la page chaque seconde pendant que nginx la sert.
