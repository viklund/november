#!/bin/sh

QS=$1
PARROT_DIR=/home/johan/Perl6/parrot-svn
REQUEST_METHOD=GET \
QUERY_STRING=$QS \
exec $PARROT_DIR/parrot $PARROT_DIR/languages/perl6/perl6.pbc wiki
