# Bravo !

Tu as ajouté deux probes au Deployment `echo-base` et observé leur effet :

1. **readinessProbe HTTP** (`GET /healthz` sur le port 80) : le nouveau pod n'est devenu `Ready` qu'après le succès de la probe, et le rollout a attendu ce moment pour arrêter l'ancien pod.
2. **livenessProbe exec** (`stat /tmp/life-signs`) : elle réussit tant que le fichier existe.
3. **Échec de la liveness** : après la suppression du fichier, le kubelet a tué puis redémarré le conteneur, dans le même pod (`RESTARTS` à 1), et la commande de démarrage a recréé le fichier.

## Points clés à retenir

- **readinessProbe** : en cas d'échec, le pod n'est plus `Ready` et les Services cessent de lui envoyer du trafic. Le conteneur **n'est pas redémarré**. Elle s'exécute pendant toute la vie du conteneur, pas seulement au démarrage.
- **livenessProbe** : après `failureThreshold` échecs consécutifs, le kubelet **redémarre le conteneur**. Le pod garde son nom et son nœud ; seul le compteur `RESTARTS` augmente.
- Une probe `httpGet` réussit si le code HTTP est compris entre 200 et 399 ; une probe `exec` réussit si la commande renvoie `0`. Il existe aussi `tcpSocket` et `grpc`.
- Valeurs par défaut : `initialDelaySeconds: 0`, `periodSeconds: 10`, `timeoutSeconds: 1`, `successThreshold: 1`, `failureThreshold: 3`.
- La liveness n'attend pas la readiness. Pour une application lente à démarrer, utilise `initialDelaySeconds` ou une **startupProbe** : sinon le conteneur peut être redémarré en boucle avant même d'avoir fini de démarrer.
- Les probes font partie du pod template : les ajouter ou les modifier déclenche un rollout.

## Pour aller plus loin

- Configurer les probes : https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Les trois types de probes : https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
