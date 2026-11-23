# Étape 3 — Faire échouer la livenessProbe

Que se passe-t-il quand la livenessProbe échoue ? Pour le voir, tu vas supprimer le fichier qu'elle surveille.

## 1. Noter l'état de départ

`kubectl -n hoth get pods`{{exec}}

Note le nom du pod. `RESTARTS` est à `0`.

## 2. Supprimer /tmp/life-signs

`kubectl -n hoth exec deploy/echo-base -- rm /tmp/life-signs`{{exec}}

## 3. Observer la réaction du kubelet

`kubectl -n hoth get pods -w`{{exec}}

Au prochain passage de la probe (au plus 7 secondes plus tard, la valeur de `periodSeconds`), `stat` échoue. Comme `failureThreshold` vaut 1, le kubelet tue aussitôt le conteneur et le redémarre :

- `RESTARTS` passe à `1` ;
- le pod passe brièvement à `0/1` : le nouveau conteneur doit à nouveau réussir sa readinessProbe ;
- puis il revient à `1/1`.

Quitte avec `Ctrl+C`.

Le **nom du pod n'a pas changé** : le pod n'a pas été recréé par le Deployment. C'est son conteneur qui a été redémarré par le kubelet, dans le même pod, sur le même nœud.

## 4. Lire les événements

`kubectl -n hoth describe pod -l app=echo-base`{{exec}}

Dans la section `Events`, en bas, repère :

- `Unhealthy` : `Liveness probe failed:` suivi de l'erreur de `stat` (le fichier n'existe pas) ;
- `Killing` : `Container echo-base failed liveness probe, will be restarted`.

Plus haut, dans la description du conteneur, `Restart Count` vaut `1` et `Last State` décrit le conteneur précédent, arrêté.

## 5. Constater que le fichier est revenu

`kubectl -n hoth exec deploy/echo-base -- stat /tmp/life-signs`{{exec}}

Le fichier existe à nouveau. Un conteneur redémarré repart de l'image : ce qui avait été modifié dans son système de fichiers (hors volumes) est perdu, et sa commande de démarrage a recréé `/tmp/life-signs`. C'est pour cela qu'un redémarrage suffit souvent à remettre en marche une application bloquée.
