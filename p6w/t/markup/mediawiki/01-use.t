use v6;

use Test;
plan 1;

my $used_successfully = False;
try {
  use Text::Markup::Wiki::MediaWiki;
  $used_successfully = True;
}

ok( $used_successfully, "Text::Markup::Wiki::MediaWiki can be use:d" );

# vim:ft=perl6
