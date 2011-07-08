use v6;

use Test;
plan 4;

use Text::Markup::Wiki::Minimal;

my %h =
    '<'  => 'lt',
    '>'  => 'gt',
    '&'  => 'amp',
    '\'' => '#039';

my $converter = Text::Markup::Wiki::Minimal.new;

for %h.kv -> $input, $abbr {
    my $expected_escape = '&' ~ $abbr ~ ';';
    my $expected_output = "<p>{$expected_escape}</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, "$input -> $expected_escape" );
}

# vim:ft=perl6
