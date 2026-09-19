# Application multi-conteneurs — conflit de port

Le namespace `tatooine` contient un déploiement `twin-suns`, dont le
pod fait tourner 2 conteneurs : `httpd` et `nginx`.

Tu vas d'abord extraire les logs des deux conteneurs, puis diagnostiquer
et corriger un problème qui les empêche de fonctionner correctement
ensemble.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
