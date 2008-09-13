use v6;

use Test;
plan 1;

use Wiki::Markup::Minimal;

my $converter = Wiki::Markup::Minimal.new;

my $input = 'normal text';
my $expected_output = '<p>normal text</p>';
my $actual_output = $converter.format($input);

is( $expected_output, $actual_output, 'normal text goes through unchanged' );
