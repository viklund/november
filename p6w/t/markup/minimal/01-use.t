use v6;

use Test;
plan 1;

my $used_successfully = False;
try {
  use Text__Markup__Wiki__Minimal;
  $used_successfully = True;
}

ok( $used_successfully, "use Text__Markup__Wiki__Minimal" );
