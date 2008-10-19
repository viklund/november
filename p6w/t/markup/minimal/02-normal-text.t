use v6;

use Test;
plan 1;

use Text__Markup__Wiki__Minimal;

my $converter = Text__Markup__Wiki__Minimal.new;

my $input = 'normal text';
my $expected_output = '<p>normal text</p>';
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, 'normal text goes through unchanged' );
