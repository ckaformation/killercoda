# Cycle de vie d'une release Helm

Une release Helm `falco` (chart `falcosecurity/falco`, namespace
`falco`) est déjà déployée, avec `falco.log_level` sur `warning`.

Tu vas :

1. Installer une nouvelle release (`podinfo`) depuis zéro.
2. Mettre à jour la release `falco` existante.
3. Revenir en arrière sur cette même release.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
