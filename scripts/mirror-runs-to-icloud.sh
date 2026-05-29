#!/usr/bin/env bash
# mirror-runs-to-icloud.sh — espeja los outputs ligeros del harness a iCloud
# Drive para poder revisarlos desde el iPhone/iPad sin tocar los originales.
#
# Origen:  ~/GuachinchesHarness/runs/<run_id>/...
# Destino: ~/Library/Mobile Documents/com~apple~CloudDocs/GuachinchesHarness-Screenshots/<run_id>/...
#
# Qué se copia (legible y pequeño):
#   - screenshots/**            (PNGs)
#   - findings-*.json
#   - contract.md / contract.json
#   - spec.md
#   - generator-notes.md
#   - input.md
#   - trace.jsonl
#
# Qué NO se copia (logs gigantes, cache, sesiones):
#   - *-iter-*.log              (planner/generator/evaluator logs, 100-300KB c/u)
#   - patrol-*.log              (logs raw de patrol, ruido)
#   - flutter-run.log
#   - .session-*  .iter-*  .flutter.pid  preflight.env
#
# Uso:
#   ./scripts/mirror-runs-to-icloud.sh            # espeja TODOS los runs
#   ./scripts/mirror-runs-to-icloud.sh <run_id>   # espeja solo uno
#
# Pensado para correr a mano o desde el hook post-run del harness.

set -euo pipefail

SRC_ROOT="${HARNESS_VAULT:-${HOME}/GuachinchesHarness}/runs"
DST_ROOT="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/GuachinchesHarness-Screenshots"

if [[ ! -d "${SRC_ROOT}" ]]; then
  echo "error: no hay vault de runs en ${SRC_ROOT}" >&2
  exit 1
fi

mkdir -p "${DST_ROOT}"

mirror_one() {
  local run_id="$1"
  local src="${SRC_ROOT}/${run_id}"
  local dst="${DST_ROOT}/${run_id}"
  if [[ ! -d "${src}" ]]; then
    echo "skip: ${run_id} (no existe)" >&2
    return 0
  fi
  mkdir -p "${dst}"
  # rsync con --include explícito + --exclude='*' al final = whitelist puro.
  rsync -a --delete \
    --include='screenshots/' \
    --include='screenshots/**' \
    --include='findings-*.json' \
    --include='contract.md' \
    --include='contract.json' \
    --include='spec.md' \
    --include='generator-notes.md' \
    --include='input.md' \
    --include='trace.jsonl' \
    --exclude='*' \
    "${src}/" "${dst}/"
  echo "✓ ${run_id} → iCloud"
}

if [[ $# -ge 1 ]]; then
  mirror_one "$1"
else
  # Espejar todos. Saltar 'index.jsonl' que no es un run.
  for d in "${SRC_ROOT}"/*/; do
    run_id="$(basename "${d}")"
    [[ "${run_id}" == "index.jsonl" ]] && continue
    mirror_one "${run_id}"
  done
  # El index global también es útil tenerlo en iCloud para ver el histórico.
  if [[ -f "${SRC_ROOT}/index.jsonl" ]]; then
    cp -f "${SRC_ROOT}/index.jsonl" "${DST_ROOT}/index.jsonl"
    echo "✓ index.jsonl → iCloud"
  fi
fi

echo "Destino: ${DST_ROOT}"
