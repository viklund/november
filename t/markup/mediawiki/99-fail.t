use v6;

use Test;
plan 1;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;

# Issue #16: The MediaWiki parser crashes if it gets fed a page with at least
# one trailing new-line (possibly followed by spaces).

my $input = "Foo\n";
my $succeeded = False;
try {
  my $actual_output = $converter.format($input);
  $succeeded = True;
}

ok( $succeeded, q[the parser doesn't crash on a final newline] ); # '

# vim:ft=perl6
