#!/bin/sh

QS=$1
set -u PARROT_DIR
REQUEST_METHOD=GET \
QUERY_STRING=$QS \
HTTP_COOKIE='session_id=673766.5765' \
exec $PARROT_DIR/parrot $PARROT_DIR/languages/perl6/perl6.pbc wiki
