use v6;

use Test;
plan 1;

use Text::Markup::Wiki::MediaWiki;

# Skipping this until we figure out why the mdash entity isn't emitted
# correctly by Apache.
skip 1, 'Apache does not emit &mdash; correctly';

my $converter = Text::Markup::Wiki::MediaWiki.new;

my $input           = '&mdash;';
my $expected_output = '<p>—</p>';
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, '&mdash; is handled' );
