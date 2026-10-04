#!/bin/sh
# Runs the busted specs inside LÖVE. Extra args are passed to busted.
cd "$(dirname "$0")" || exit 1
eval "$(luarocks path --lua-version 5.1)"
exec love . --test "$@"
