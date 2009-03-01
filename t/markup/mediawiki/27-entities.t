use v6;

use Test;
plan 1;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;

my $input           = '&mdash;';
my $expected_output = '<p>—</p>';
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, '&mdash; is handled' );
