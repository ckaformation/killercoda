#!/usr/bin/env bash
# ceph-rbd-app-scale.sh — Scale à 0 (puis restaure) les Deployments et StatefulSets
# qui montent un PVC sur la StorageClass RBD d'ODF (mode externe).
# Les DeploymentConfigs sont volontairement ignorées.
#
# Usage : ./ceph-rbd-app-scale.sh [--exclude-system] {list|down|check|up}
#   list    affiche ce qui serait arrêté (aucune modification)
#   down    mémorise les replicas en annotation puis scale à 0
#   check   liste les volumes RBD encore attachés à un nœud (tous namespaces)
#   up      restaure les replicas mémorisés
#
# Par défaut, TOUS les namespaces sont traités, y compris openshift* et kube*.
#   -x, --exclude-system   ignore les namespaces openshift* et kube*
#                          (s'applique à list, down et up)
#
# Variables optionnelles :
#   SC          StorageClass ciblée (défaut : ocs-external-storagecluster-ceph-rbd)
#   EXCLUDE_NS  regex personnalisée de namespaces à ignorer (défaut : aucune)
set -euo pipefail

SC="${SC:-ocs-external-storagecluster-ceph-rbd}"
EXCLUDE_NS="${EXCLUDE_NS:-}"
ANNOT="rbd-scaledown/replicas"
RBD_DRIVER="openshift-storage.rbd.csi.ceph.com"

usage() { echo "usage: $0 [--exclude-system] {list|down|check|up}" >&2; exit 1; }

cmd=""
for arg in "$@"; do
  case "$arg" in
    -x|--exclude-system) EXCLUDE_NS='^(openshift|kube)' ;;
    list|down|check|up)  [ -z "$cmd" ] || usage; cmd="$arg" ;;
    *)                   usage ;;
  esac
done
cmd="${cmd:-list}"

command -v jq >/dev/null || { echo "jq est requis" >&2; exit 1; }

tabulate() { if command -v column >/dev/null; then column -t; else cat; fi; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

kinds="deployments.apps,statefulsets.apps"

# Sortie : "<namespace> <kind>/<nom> <replicas>" pour chaque workload concerné
targets() {
  oc get sc "$SC" >/dev/null
  oc get pvc -A -o json > "$tmp/pvc.json"
  oc get "$kinds" -A -o json > "$tmp/wl.json"

  jq -r --arg sc "$SC" --arg ex "$EXCLUDE_NS" --slurpfile pvc "$tmp/pvc.json" '
    [ $pvc[0].items[] | select(.spec.storageClassName == $sc)
      | "\(.metadata.namespace)/\(.metadata.name)" ] as $pvcs
    | ($pvcs | map({(.): true}) | add // {}) as $set
    | .items[]
    | select($ex == "" or (.metadata.namespace | test($ex) | not))
    | select((.spec.replicas // 1) > 0)
    | .metadata.namespace as $ns | .metadata.name as $n
    | ( [ .spec.template.spec.volumes[]?.persistentVolumeClaim.claimName // empty
          | "\($ns)/\(.)" ]
        + ( if .kind == "StatefulSet" then
              [ .spec.volumeClaimTemplates[]?.metadata.name as $t
                | $pvcs[] | select(test("^\($ns)/\($t)-\($n)-[0-9]+$")) ]
            else [] end )
      ) as $used
    | select(any($used[]; $set[.] == true))
    | "\($ns) \(.kind | ascii_downcase)/\($n) \(.spec.replicas // 1)"
  ' "$tmp/wl.json"
}

down() {
  targets > "$tmp/targets"
  [ -s "$tmp/targets" ] || { echo "Aucun workload actif sur $SC."; return; }
  while read -r ns obj rep; do
    echo ">> $ns $obj : $rep -> 0"
    oc annotate -n "$ns" "$obj" "$ANNOT=$rep" --overwrite >/dev/null
    oc scale -n "$ns" "$obj" --replicas=0
  done < "$tmp/targets"
}

up() {
  oc get "$kinds" -A -o json | jq -r --arg a "$ANNOT" --arg ex "$EXCLUDE_NS" '
    .items[] | select(.metadata.annotations[$a]?)
    | select($ex == "" or (.metadata.namespace | test($ex) | not))
    | "\(.metadata.namespace) \(.kind | ascii_downcase)/\(.metadata.name) \(.metadata.annotations[$a])"
  ' > "$tmp/restore"
  [ -s "$tmp/restore" ] || { echo "Rien à restaurer."; return; }
  while read -r ns obj rep; do
    echo "<< $ns $obj : 0 -> $rep"
    oc scale -n "$ns" "$obj" --replicas="$rep"
    oc annotate -n "$ns" "$obj" "$ANNOT-" >/dev/null
  done < "$tmp/restore"
}

check() {
  oc get volumeattachment -o json > "$tmp/va.json"
  oc get pv -o json > "$tmp/pv.json"
  jq -r --arg d "$RBD_DRIVER" --slurpfile pv "$tmp/pv.json" '
    ($pv[0].items | map({(.metadata.name):
        "\(.spec.claimRef.namespace // "?")/\(.spec.claimRef.name // "?")"}) | add // {}) as $claims
    | .items[] | select(.spec.attacher == $d)
    | "\($claims[.spec.source.persistentVolumeName] // "?") \(.spec.source.persistentVolumeName) \(.spec.nodeName)"
  ' "$tmp/va.json" > "$tmp/attached"
  if [ -s "$tmp/attached" ]; then
    echo "Volumes RBD encore attachés (PVC PV NODE) :"
    tabulate < "$tmp/attached"
  else
    echo "OK : plus aucun volume RBD attaché."
  fi
}

[ -n "$EXCLUDE_NS" ] && echo "(namespaces ignorés : $EXCLUDE_NS)" >&2

case "$cmd" in
  list)  targets | tabulate ;;
  down)  down ;;
  up)    up ;;
  check) check ;;
esac
