#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build/iphone_site"
PRESET_NAME="Web PWA"
SAVED_GODOT_PATH="$ROOT_DIR/.godot_path"

clear || true
printf "\n"
printf "=============================================\n"
printf "      RIFT NOMAD - EXPORT IPHONE / PWA       \n"
printf "=============================================\n\n"

resolve_app_executable() {
  local app_path="$1"
  local executable

  [[ -d "$app_path" ]] || return 1

  # Godot standard / Mono builds.
  for executable in \
    "$app_path/Contents/MacOS/Godot" \
    "$app_path/Contents/MacOS/Godot_mono"; do
    if [[ -x "$executable" ]]; then
      echo "$executable"
      return 0
    fi
  done

  # Fallback: first executable in Contents/MacOS.
  if [[ -d "$app_path/Contents/MacOS" ]]; then
    executable="$(find "$app_path/Contents/MacOS" -maxdepth 1 -type f -perm -111 2>/dev/null | head -n 1 || true)"
    if [[ -n "$executable" ]]; then
      echo "$executable"
      return 0
    fi
  fi

  return 1
}

find_godot() {
  local candidate=""
  local app_path=""
  local found=""

  # 1) Path manually remembered from a previous run.
  if [[ -f "$SAVED_GODOT_PATH" ]]; then
    candidate="$(cat "$SAVED_GODOT_PATH" 2>/dev/null || true)"
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  # 2) Explicit environment variable.
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
    echo "$GODOT_BIN"
    return 0
  fi

  # 3) Common application / Homebrew locations.
  local candidates=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "/Applications/Godot_mono.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot_mono.app/Contents/MacOS/Godot"
    "/opt/homebrew/bin/godot"
    "/opt/homebrew/bin/godot4"
    "/usr/local/bin/godot"
    "/usr/local/bin/godot4"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  # 4) Shell PATH (useful for Homebrew installs).
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return 0
  fi

  # 5) Spotlight: catches apps named Godot_v4.x-stable.app, etc.
  if command -v mdfind >/dev/null 2>&1; then
    while IFS= read -r app_path; do
      [[ "$app_path" == *.app ]] || continue
      found="$(resolve_app_executable "$app_path" || true)"
      if [[ -n "$found" ]]; then
        echo "$found"
        return 0
      fi
    done < <(mdfind 'kMDItemFSName == "Godot*.app"c' 2>/dev/null | head -n 30)
  fi

  # 6) Lightweight search in the folders where Godot is often left after download.
  for app_path in \
    /Applications/Godot*.app \
    "$HOME"/Applications/Godot*.app \
    "$HOME"/Downloads/Godot*.app \
    "$HOME"/Desktop/Godot*.app; do
    [[ -e "$app_path" ]] || continue
    found="$(resolve_app_executable "$app_path" || true)"
    if [[ -n "$found" ]]; then
      echo "$found"
      return 0
    fi
  done

  return 1
}

choose_godot_manually() {
  local app_path=""
  local executable=""

  if ! command -v osascript >/dev/null 2>&1; then
    return 1
  fi

  echo "Godot n'a pas été détecté automatiquement."
  echo "Ouverture d'une fenêtre Finder : sélectionne simplement Godot.app."
  echo

  app_path="$(osascript <<'APPLESCRIPT' 2>/dev/null || true
try
  set chosenApp to choose application with prompt "Sélectionne l'application Godot"
  tell application "Finder" to set appPath to POSIX path of (chosenApp as alias)
  return appPath
on error
  return ""
end try
APPLESCRIPT
)"

  app_path="${app_path%/}"
  [[ -n "$app_path" ]] || return 1

  executable="$(resolve_app_executable "$app_path" || true)"
  [[ -n "$executable" ]] || return 1

  printf '%s\n' "$executable" > "$SAVED_GODOT_PATH"
  echo "$executable"
  return 0
}

pause_and_exit() {
  echo
  read -k 1 "?Appuie sur une touche pour fermer..." || true
  exit "${1:-1}"
}

GODOT_BIN="$(find_godot || true)"
if [[ -z "$GODOT_BIN" ]]; then
  GODOT_BIN="$(choose_godot_manually || true)"
fi

if [[ -z "$GODOT_BIN" ]]; then
  echo "ERREUR : impossible de localiser Godot."
  echo
  echo "Tu n'as PAS besoin de renommer Godot ni de le déplacer dans Applications."
  echo "Relance cette commande et sélectionne Godot.app dans la fenêtre Finder."
  echo
  echo "Si Godot n'est pas encore téléchargé, installe-le puis relance la commande."
  pause_and_exit 1
fi

# Remember a working path for next time.
printf '%s\n' "$GODOT_BIN" > "$SAVED_GODOT_PATH"

echo "Godot détecté : $GODOT_BIN"
echo "Projet : $ROOT_DIR"
echo

if [[ ! -f "$ROOT_DIR/project.godot" ]]; then
  echo "ERREUR : project.godot est introuvable."
  pause_and_exit 1
fi

if [[ ! -f "$ROOT_DIR/export_presets.cfg" ]]; then
  echo "ERREUR : export_presets.cfg est introuvable."
  pause_and_exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "[1/4] Import des ressources..."
"$GODOT_BIN" --headless --path "$ROOT_DIR" --editor --quit >/dev/null

echo "[2/4] Export Web/PWA optimisé iPhone..."
if ! "$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "$PRESET_NAME" "$BUILD_DIR/index.html"; then
  echo
  echo "ERREUR : l'export Godot a échoué."
  echo "Vérifie dans Godot : Éditeur > Gérer les modèles d'export."
  echo "Le modèle Web doit être installé pour ta version de Godot."
  pause_and_exit 1
fi

if [[ ! -f "$BUILD_DIR/index.html" ]]; then
  echo
  echo "ERREUR : l'export n'a pas généré index.html."
  pause_and_exit 1
fi

echo "[3/4] Optimisation Safari / iPhone / GitHub Pages..."

python3 - "$BUILD_DIR/index.html" <<'PY_PATCH'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")

# Patch any viewport generated by Godot, rather than relying on one exact string.
viewport = '<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, viewport-fit=cover">'
if re.search(r'<meta\s+name=["\']viewport["\'][^>]*>', html, flags=re.I):
    html = re.sub(r'<meta\s+name=["\']viewport["\'][^>]*>', viewport, html, count=1, flags=re.I)
else:
    html = html.replace('</head>', viewport + '\n</head>', 1)

marker = "</style>"
patch = r"""

/* Rift Nomad - iPhone / PWA framing */
html, body {
    width: 100%;
    height: 100%;
    min-height: 100%;
    background: #01040d;
    overflow: hidden;
    overscroll-behavior: none;
    -webkit-user-select: none;
    user-select: none;
    -webkit-touch-callout: none;
}

body {
    position: fixed;
    inset: 0;
    width: 100vw;
    height: 100vh;
    height: 100dvh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    margin: 0;
}

#canvas {
    position: absolute;
    inset: 0;
    width: 100vw !important;
    height: 100vh !important;
    width: 100dvw !important;
    height: 100dvh !important;
    max-width: 100%;
    max-height: 100%;
    margin: auto;
    display: block;
    touch-action: none;
}

#status {
    position: fixed;
    inset: 0;
    width: 100vw;
    height: 100vh;
    width: 100dvw;
    height: 100dvh;
    background: #01040d !important;
}

#status-splash {
    width: min(72vw, 760px) !important;
    height: min(72vh, 520px) !important;
    max-width: 72vw !important;
    max-height: 72vh !important;
    object-fit: contain !important;
}
"""

if "Rift Nomad - iPhone / PWA framing" not in html:
    if marker in html:
        html = html.replace(marker, patch + "\n" + marker, 1)
    else:
        html = html.replace('</head>', '<style>' + patch + '</style>\n</head>', 1)

path.write_text(html, encoding="utf-8")
PY_PATCH

touch "$BUILD_DIR/.nojekyll"

# Replace only the previous web export at the repository root.
rm -f \
  "$ROOT_DIR/index.html" \
  "$ROOT_DIR/index.js" \
  "$ROOT_DIR/index.wasm" \
  "$ROOT_DIR/index.pck" \
  "$ROOT_DIR/index.png" \
  "$ROOT_DIR/index.icon.png" \
  "$ROOT_DIR/index.apple-touch-icon.png" \
  "$ROOT_DIR/index.manifest.json" \
  "$ROOT_DIR/index.service.worker.js" \
  "$ROOT_DIR/.nojekyll"

find "$BUILD_DIR" -maxdepth 1 -type f -exec cp -f {} "$ROOT_DIR/" ';'

echo "[4/4] Vérification..."
required=(index.html index.js index.wasm index.pck index.manifest.json index.service.worker.js)
for file in "${required[@]}"; do
  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    echo "ERREUR : $file manque après l'export."
    pause_and_exit 1
  fi
done

printf "\n=============================================\n"
printf " EXPORT TERMINÉ AVEC SUCCÈS\n"
printf "=============================================\n\n"
echo "Les fichiers GitHub Pages ont été mis à jour à la racine du projet."
echo
echo "Dans GitHub Desktop :"
echo "  1. Vérifie les fichiers modifiés"
echo "  2. Commit to main"
echo "  3. Push origin"
echo
echo "Copie de l'export conservée ici :"
echo "$BUILD_DIR"
echo

open "$ROOT_DIR" >/dev/null 2>&1 || true
read -k 1 "?Appuie sur une touche pour fermer..." || true
