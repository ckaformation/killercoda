# Troubleshooting cluster & découverte de service

Ce scénario se déroule en deux temps.

Dans un premier temps, tu vas devoir **investiguer un cluster qui ne se
comporte pas normalement**. Aucun indice supplémentaire ici — à toi de
mener l'enquête avec les outils habituels (`kubectl get`, `describe`,
`logs`...). Des indices sont disponibles en cas de besoin, dans des
menus dépliants au fil de l'étape 1.

Dans un second temps, une fois le cluster remis d'aplomb, tu
déploieras une application et observeras comment la découverte de
service fonctionne entre deux namespaces différents.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
