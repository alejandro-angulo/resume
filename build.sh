#!/usr/bin/env bash

set -e

# Following variables are set via sed in the buildPhase step
PREFIX=""
# Intentionally overriding PATH so supressing shellcheck
# shellcheck disable=SC2123
PATH=""
NERDFONTS=""

DEBUG=false
DIR=$(mktemp -d)
RES=$(pwd)/alejandro_resume.pdf
LOG=$(pwd)/alejandro_resume.log

function usage {
echo "Usage: $(basename "$0") [-h] [-d] [-e EMAIL] [-p PHONENUMBER]"
echo '    -h              Prints this usage message.'
echo ""
echo '    -d              Saves latexmk log file (will be named alejandro_resume.log)'
echo ""
echo '    -e EMAIL        Sets email address used when building document.'
echo '                    Can also be set with EMAIL environment variable.'
echo ""
echo '    -p PHONENUMBER  Sets phone number used when building the document.'
echo '                    Can also be set with PHONENUMBER environment variable.'
}

while getopts ':de:p:h' flag; do
case $flag in
  'd') DEBUG=true;;
  # Overrides EMAIL and PHONENUMBER envvars if set
  'e') EMAIL="$OPTARG";;
  'p') PHONENUMBER="$OPTARG";;
  'h') usage && exit;;
  ?) usage && exit 1;;
esac
done

cd "$PREFIX"/share || exit 1
mkdir -p "$DIR/.texcache/texmf-var"

export EMAIL
export PHONENUMBER

# Set via sed in buildPhase (needs to be set after we have input values (e.g.
# EMAIL and PHONENUMBER)
TEXVARS=""

env TEXFMHOME="$DIR/.texcache" TEXMFVAR="$DIR/.texcache/texmf-var" \
  OSFONTDIR="$NERDFONTS"/share/fonts \
latexmk -interaction=nonstopmode -pdf -lualatex \
-output-directory="$DIR" \
-pretex="$TEXVARS" \
-usepretex alejandro_resume.tex

mv "$DIR/alejandro_resume.pdf" "$RES"

if $DEBUG; then
mv "$DIR/alejandro_resume.log" "$LOG"
fi

rm -rf "$DIR"
