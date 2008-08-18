#!/bin/sh

QS=$1
if [ "$PARROT_DIR" == "" ]; then
  cat <<EXPLANATION
In order to run this script, you need to set your PARROT_DIR first.
If you\'re using bash, you can do it like this:
export PARROT_DIR=/path/to/your/installation/of/parrot/
Also consider putting this line into your \~/.bashrc -- that way,
PARROT_DIR will be automatically set for you in every bash session.
EXPLANATION
  exit
fi
REQUEST_METHOD=GET \
QUERY_STRING=$QS \
HTTP_COOKIE='session_id=673766.5765' \
exec $PARROT_DIR/parrot $PARROT_DIR/languages/perl6/perl6.pbc wiki
