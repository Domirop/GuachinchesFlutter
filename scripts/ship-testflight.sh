#!/usr/bin/env bash
# Build local del .ipa (coste cero, en tu Mac) + subida a TestFlight.
# Uso: ./scripts/ship-testflight.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# Build number AUTOMÁTICO: nº de commits → siempre sube, Apple no lo rechaza.
# Override puntual: BUILD_NUMBER=170 ./scripts/ship-testflight.sh
# (útil si se re-sube sin commits nuevos: Apple exige un número mayor).
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD)}"
# Marketing version: la parte antes del '+' en pubspec.yaml (ej. 4.5.0).
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1)"

echo "▸ Compilando $VERSION (build $BUILD_NUMBER) …"
flutter build ipa \
  --release \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --export-method app-store

echo "▸ Subiendo a TestFlight …"
( cd ios && fastlane beta )

echo "✓ Listo: $VERSION ($BUILD_NUMBER) en TestFlight."
