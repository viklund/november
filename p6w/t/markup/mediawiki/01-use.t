use v6;

use Test;
plan 1;

my $used_successfully = False;
try {
  use Text::Markup::Wiki::MediaWiki;
  $used_successfully = True;
}

ok( $used_successfully, "use Text::Markup::Wiki::MediaWiki" );
