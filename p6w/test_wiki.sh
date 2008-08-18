#!/bin/sh

QS=$1
if [ "$PARROT_DIR" == "" ]; then
  echo Hello, we\'d like you to set your PARROT_DIR first.
  echo If you\'re using bash, you do it like this:
  echo export PARROT_DIR=/path/to/your/installation/of/parrot/
  echo Also consider putting this line into your \~/.bashrc for great justice.
  exit
fi
REQUEST_METHOD=GET \
QUERY_STRING=$QS \
HTTP_COOKIE='session_id=673766.5765' \
exec $PARROT_DIR/parrot $PARROT_DIR/languages/perl6/perl6.pbc wiki
