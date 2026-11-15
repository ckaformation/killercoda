# Étape 1 — Init container et volume emptyDir

Un **init container** s'exécute **avant** les containers de l'application et doit se terminer avec succès. Ici, il écrit la page d'accueil dans un volume `emptyDir`, que nginx sert ensuite.

## 1. Attendre l'environnement

`k wait --for=condition=Available deploy --all --timeout=120s`{{exec}}

Si la commande répond `no matching resources found`, la préparation n'est pas terminée : attends quelques secondes et relance-la.

## 2. Observer l'existant

`k get deploy,pods -o wide`{{exec}}

`cat /root/dagobah.yaml`{{exec}}

Récupère l'IP du pod de `dagobah` et interroge nginx :

`IP=$(k get pod -l app=dagobah -o jsonpath='{.items[0].status.podIP}')`{{exec}}

`curl -s $IP | grep h1`{{exec}}

Tu lis la page par défaut de l'image nginx : `<h1>Welcome to nginx!</h1>`.

## 3. Ajouter le volume et l'init container

`vi /root/dagobah.yaml`{{exec}}

Complète le `spec` du template avec les trois blocs marqués, en respectant l'indentation :

```yaml
    spec:
      terminationGracePeriodSeconds: 1
      volumes:                 # à ajouter (bloc)
      - name: html
        emptyDir: {}
      initContainers:          # à ajouter (bloc)
      - name: yoda
        image: busybox
        command: ["sh", "-c", "echo '<h1>Hello from init</h1>' > /usr/share/nginx/html/index.html"]
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

- `volumes` se déclare au niveau du **pod** ; chaque container choisit où le monter avec `volumeMounts`.
- `yoda` et `nginx` montent le **même** volume `html` : ce que `yoda` écrit, nginx le lit.
- Le montage masque le contenu d'origine de `/usr/share/nginx/html` dans l'image nginx.

## 4. Appliquer et tester

`k apply -f /root/dagobah.yaml`{{exec}}

`k rollout status deploy dagobah`{{exec}}

`k get pods -l app=dagobah`{{exec}}

La colonne `READY` affiche `1/1` : l'init container, terminé, n'est pas compté. S'il reste un pod `Terminating`, attends qu'il disparaisse.

Le pod a été recréé : son IP a changé. Récupère-la de nouveau :

`IP=$(k get pod -l app=dagobah -o jsonpath='{.items[0].status.podIP}')`{{exec}}

`curl -s $IP`{{exec}}

Tu lis `<h1>Hello from init</h1>` : la page écrite par l'init container.
