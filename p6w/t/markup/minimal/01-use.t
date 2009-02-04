use v6;

use Test;
plan 1;

my $used_successfully = False;
try {
  use Text::Markup::Wiki::Minimal;
  $used_successfully = True;
}

ok( $used_successfully, "use Text::Markup::Wiki::Minimal" );

# vim:ft=perl6
