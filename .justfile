# The template testing is broken, so it's not tested. However, there is a
# duplicate "template" test that is "persistent" instead of just
# "compile-only". The only source code difference is the relative paths for
# dependent files/imports.
# https://github.com/typst-community/tytanic/issues/184

DEFAULT_ARGS := "\
--ppi 100 \
--font-path fonts \
--expression 'not template()' \
"

PREVIEW_DIR := env(
  'TYPST_PACKAGE_CACHE_PATH',
  env('XDG_CACHE_HOME', env('HOME') / '.cache') / 'typst' / 'packages',
) / 'preview'

PACKAGE_NAME := shell(
  'grep "$1" typst.toml | sed -E "$2"',
  '^name',
  's/[^"]+"([^"]+)".*/\1/',
)

PACKAGE_VERSION := shell(
  'grep "$1" typst.toml | grep -o "$2"',
  '^version',
  '[0-9]\+\.[0-9]\+\.[0-9]\+',
)

PRE_COMMIT_SCRIPT := "\
#!/usr/bin/env sh
# Run tests.
just test\
"

alias t := test
alias ut := update-test
alias i := install
alias un := uninstall

# Run tests.
test *args: pre-commit
  tt run {{DEFAULT_ARGS}} {{args}}

# Update tests.
update-test *args: pre-commit
  tt update {{DEFAULT_ARGS}} {{args}}

# Install the package by linking it to this repository.
install:
  mkdir -p '{{PREVIEW_DIR / PACKAGE_NAME}}'
  rm -rf '{{PREVIEW_DIR / PACKAGE_NAME / PACKAGE_VERSION}}'
  ln -s "$PWD" '{{PREVIEW_DIR / PACKAGE_NAME / PACKAGE_VERSION}}'
  @ echo
  @ echo 'Installed. To uninstall run:'
  @ echo 'just uninstall'

# Uninstall the package allowing the upstream version to be used.
uninstall:
  rm -rf '{{PREVIEW_DIR / PACKAGE_NAME / PACKAGE_VERSION}}'
  @ echo
  @ echo 'Uninstalled.'

# Initialize the pre-commit Git hook, overriding (potentially) existing one.
pre-commit:
  echo '{{PRE_COMMIT_SCRIPT}}' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit

download-fonts link="https://www.dropbox.com/scl/fi/ejy8910blatsgpzvcyhf8/UnitOT.zip?rlkey=7c550m3rpvd6hovt1o9s5oiwf&dl=0":
  #!/bin/sh
  set -eu
  trap 'rm -f cookies UnitOT.zip' INT
  curl --silent --cookie-jar cookies --output /dev/null 'https://www.dropbox.com'
  token=$(grep __Host-js_csrf cookies | cut -d "$(printf '\t')" -f 7)
  response=$(curl --silent --cookie cookies --header "X-CSRF-Token: $token" \
    --json '{"link_url":"{{link}}","optional_rlkey":"","optional_grant_book":""}' \
    'https://www.dropbox.com/2/sharing_receiving/generate_download_url')
  rm cookies
  url=$(echo "$response" | cut -d '"' -f 4)
  curl --silent --show-error --output UnitOT.zip "$url"
  mkdir -p "fonts/Unit OT"
  unzip -od "fonts/Unit OT" -j UnitOT.zip \
    UnitOT/UnitOT.otf \
    UnitOT/UnitOT-LightIta.otf
  # unzip -qod fonts UnitOT.zip
  rm -f UnitOT.zip

patch-fonts:
  fontforge -script ./scripts/patch_font_files.py "fonts/Unit OT" "fonts/Unit OT (patched)"

init: pre-commit download-fonts patch-fonts
