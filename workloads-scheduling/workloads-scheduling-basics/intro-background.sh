#!/bin/bash
# ============================================================================
# Préparation silencieuse minimale : ce scénario ne nécessite rien de plus
# qu'un cluster fonctionnel — tous les objets (Pod, Deployment, StatefulSet)
# sont créés par l'élève au fil des étapes.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

exit 0
