# Troubleshooting stockage & déploiement PostgreSQL

Dans un premier temps, tu vas devoir débloquer un
`PersistentVolumeClaim` qui reste en `Pending`. Aucun indice ici : à
toi d'investiguer avec les outils habituels.

Une fois ce volume disponible, tu déploieras PostgreSQL en t'appuyant
dessus, à partir d'un template à compléter.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
