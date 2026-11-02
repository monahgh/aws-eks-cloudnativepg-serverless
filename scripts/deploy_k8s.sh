#!/usr/bin/env bash
# Installs the CloudNativePG operator and applies the lab manifests.
# Prerequisite: kubectl is pointed at the cluster (see terraform output kubeconfig_command).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

# Pin a release when you deploy; check https://cloudnative-pg.io/documentation/ for the current one.
CNPG_MANIFEST="${CNPG_MANIFEST:-https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.25/releases/cnpg-1.25.0.yaml}"

kubectl apply -f "${K8S_DIR}/00-namespace.yaml"
kubectl apply -f "${K8S_DIR}/10-storageclass-gp3.yaml"

kubectl apply --server-side -f "${CNPG_MANIFEST}"
kubectl rollout status deployment/cnpg-controller-manager -n cnpg-system --timeout=180s

kubectl apply -f "${K8S_DIR}/20-cnpg-cluster.yaml"
kubectl get cluster -n pgops
