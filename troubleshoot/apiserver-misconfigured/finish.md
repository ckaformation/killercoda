# Bravo !

Tu as appliqué, seul cette fois, la méthode de diagnostic vue dans le
scénario précédent :

- Identifié une erreur de syntaxe YAML qui empêche kubelet de charger
  un manifest de pod statique.
- Identifié un argument de ligne de commande invalide provoquant un
  crash immédiat du process.
- Identifié une référence à un fichier de certificat inexistant.
- Constaté que plusieurs erreurs cumulées se révèlent souvent en
  cascade : corriger la première fait apparaître la suivante, plutôt
  que de toutes les voir d'un coup.

## Pour aller plus loin

- Essaie de provoquer volontairement une 4ᵉ erreur (par exemple sur
  `--secure-port`) et observe où elle se situe dans la cascade.
- Compare le temps de récupération selon que tu corriges les erreurs
  une par une avec de longues pauses, ou rapidement à la suite —
  observe le `CrashLoopBackOff` et son délai croissant entre tentatives.
