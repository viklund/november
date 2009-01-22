use v6;

my @tests;

use Test::InputOutput;
plan +@tests;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
Test::InputOutput.using( { $converter.format($^input) } ).test(@tests);

# vim:ft=perl6
