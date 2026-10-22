#!/usr/bin/env bash
# ceph-rbd-app-scale.sh — Scale à 0 (puis restaure) les Deployments et StatefulSets
# qui montent un PVC sur une StorageClass ODF externe : RBD ou CephFS.
# Les DeploymentConfigs sont volontairement ignorées.
#
# Usage : ./ceph-rbd-app-scale.sh [--exclude-system] {rbd|cephfs} {list|down|check|up}
#
#   rbd       cible la StorageClass ocs-external-storagecluster-ceph-rbd
#   cephfs    cible la StorageClass ocs-external-storagecluster-cephfs
#
#   list    affiche ce qui serait arrêté, sans rien modifier (commande par défaut)
#   down    mémorise les replicas en annotation puis scale à 0
#   check   liste les pods et VolumeAttachments qui utilisent encore la StorageClass
#           (tous namespaces)
#   up      restaure les replicas mémorisés
#
# Par défaut, TOUS les namespaces sont traités, y compris openshift* et kube*.
#   -x, --exclude-system   ignore les namespaces openshift* et kube*
#                          (s'applique à list, down et up)
#
# Chaque type a sa propre annotation (rbd-scaledown/replicas, cephfs-scaledown/replicas) :
# un "up cephfs" ne relance jamais ce qu'un "down rbd" a arrêté, et inversement.
#
# Variables optionnelles :
#   SC          force une autre StorageClass que celle par défaut du type choisi
#   EXCLUDE_NS  regex personnalisée de namespaces à ignorer (défaut : aucune)
set -euo pipefail

EXCLUDE_NS="${EXCLUDE_NS:-}"
kinds="deployments.apps,statefulsets.apps"

usage() { echo "usage: $0 [--exclude-system] {rbd|cephfs} {list|down|check|up}" >&2; exit 1; }

type="" cmd=""
for arg in "$@"; do
  case "$arg" in
    -x|--exclude-system) EXCLUDE_NS='^(openshift|kube)' ;;
    rbd|cephfs)          [ -z "$type" ] || usage; type="$arg" ;;
    list|down|check|up)  [ -z "$cmd" ] || usage; cmd="$arg" ;;
    *)                   usage ;;
  esac
done
[ -n "$type" ] || usage
cmd="${cmd:-list}"

case "$type" in
  rbd)    SC="${SC:-ocs-external-storagecluster-ceph-rbd}" ;;
  cephfs) SC="${SC:-ocs-external-storagecluster-cephfs}" ;;
esac
ANNOT="${type}-scaledown/replicas"

command -v jq >/dev/null || { echo "jq est requis" >&2; exit 1; }

tabulate() { if command -v column >/dev/null; then column -t; else cat; fi; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

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
  [ -s "$tmp/restore" ] || { echo "Rien à restaurer pour $type."; return; }
  while read -r ns obj rep; do
    echo "<< $ns $obj : 0 -> $rep"
    oc scale -n "$ns" "$obj" --replicas="$rep"
    oc annotate -n "$ns" "$obj" "$ANNOT-" >/dev/null
  done < "$tmp/restore"
}

# Deux vérifications, car selon le CSIDriver (attachRequired), CephFS peut ne
# créer aucun VolumeAttachment : la liste des pods fait alors foi.
check() {
  oc get sc "$SC" >/dev/null
  oc get pvc -A -o json > "$tmp/pvc.json"
  oc get pods -A -o json > "$tmp/pods.json"
  oc get pv -o json > "$tmp/pv.json"
  oc get volumeattachment -o json > "$tmp/va.json"

  jq -r --arg sc "$SC" --slurpfile pvc "$tmp/pvc.json" '
    ($pvc[0].items | map(select(.spec.storageClassName == $sc)
        | {("\(.metadata.namespace)/\(.metadata.name)"): true}) | add // {}) as $set
    | .items[]
    | select(.status.phase != "Succeeded" and .status.phase != "Failed")
    | .metadata.namespace as $ns
    | .metadata.name as $p
    | (.spec.nodeName // "-") as $node
    | .spec.volumes[]?.persistentVolumeClaim.claimName // empty
    | select($set["\($ns)/\(.)"] == true)
    | "\($ns) \($p) \(.) \($node)"
  ' "$tmp/pods.json" > "$tmp/pods"

  jq -r --arg sc "$SC" --slurpfile pv "$tmp/pv.json" '
    ($pv[0].items | map(select(.spec.storageClassName == $sc)
        | {(.metadata.name): "\(.spec.claimRef.namespace // "?")/\(.spec.claimRef.name // "?")"})
        | add // {}) as $claims
    | .items[]
    | .spec.source.persistentVolumeName as $pvn
    | select($pvn != null and $claims[$pvn] != null)
    | "\($claims[$pvn]) \($pvn) \(.spec.nodeName)"
  ' "$tmp/va.json" > "$tmp/attached"

  if [ -s "$tmp/pods" ]; then
    echo "Pods utilisant encore $SC (NAMESPACE POD PVC NODE) :"
    tabulate < "$tmp/pods"
  else
    echo "OK : aucun pod actif n'utilise $SC."
  fi
  echo
  if [ -s "$tmp/attached" ]; then
    echo "VolumeAttachments encore présents (PVC PV NODE) :"
    tabulate < "$tmp/attached"
  else
    echo "OK : aucun VolumeAttachment sur $SC."
  fi
}

[ -n "$EXCLUDE_NS" ] && echo "(namespaces ignorés : $EXCLUDE_NS)" >&2

case "$cmd" in
  list)  targets | tabulate ;;
  down)  down ;;
  up)    up ;;
  check) check ;;
esac
