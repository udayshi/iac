#!/usr/bin/env bash

# Restores a dated web-volume backup after the web workload has been stopped.
set -euo pipefail

readonly backup_date="${1:-}"
readonly deployment_name="web"

validate_backup_date() {
  if [[ ! "$backup_date" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    echo "Usage: $0 DD-MM-YYYY" >&2
    exit 2
  fi
}

require_stopped_workload() {
  local replicas

  replicas="$(kubectl get deployment "$deployment_name" -o jsonpath='{.spec.replicas}')"
  if [[ "$replicas" != "0" ]]; then
    echo "Refusing to restore while deployment/$deployment_name has $replicas replicas." >&2
    echo "Run: kubectl scale deployment/$deployment_name --replicas=0" >&2
    exit 1
  fi
}

create_restore_job() {
  local job_name

  job_name="web-volume-restore-${backup_date}-$(date +%s)"
  kubectl apply -f - >/dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${job_name}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 86400
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: restore
          image: busybox:1.36.1
          command:
            - /bin/sh
            - -ec
            - |
              test -d "/backup/${backup_date}"
              find /restore -mindepth 1 -maxdepth 1 -exec rm -rf {} +
              tar -C "/backup/${backup_date}" -cf - . | tar -C /restore -xf -
          volumeMounts:
            - name: backup
              mountPath: /backup
              readOnly: true
            - name: restore
              mountPath: /restore
      volumes:
        - name: backup
          persistentVolumeClaim:
            claimName: web-backup-pvc
        - name: restore
          persistentVolumeClaim:
            claimName: web-pvc
EOF
  printf '%s\n' "$job_name"
}

wait_for_restore() {
  local job_name="$1"

  if ! kubectl wait --for=condition=complete "job/$job_name" --timeout=10m; then
    kubectl logs "job/$job_name" || true
    exit 1
  fi

  kubectl logs "job/$job_name"
}

main() {
  validate_backup_date
  require_stopped_workload
  wait_for_restore "$(create_restore_job)"
}

main "$@"
