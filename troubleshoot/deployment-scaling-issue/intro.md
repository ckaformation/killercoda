# Troubleshooting Horizontal Pod Autoscaler

Le namespace `kessel-run` contient un déploiement `millennium-falcon`
(image `polinux/stress:1.0.4`, 3 replicas).

Tu vas créer un `HorizontalPodAutoscaler` pour ce déploiement,
diagnostiquer un comportement inattendu, puis générer réellement de la
charge CPU pour observer le HPA en action.

Le cluster (avec `metrics-server`) se prépare en arrière-plan pendant
que tu lis ces lignes.
