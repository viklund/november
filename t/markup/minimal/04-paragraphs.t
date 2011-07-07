use v6;

use Test;
plan 1;

use Text::Markup::Wiki::Minimal;

my $converter = Text::Markup::Wiki::Minimal.new;

my @pars =
  "par 1",
  "par 2\nwith\nnewlines in it",
  "par 3";
my $input           = join "\n\n", @pars;
my $expected_output = join "\n\n", map { "<p>{$_}</p>" }, @pars;
my $actual_output   = $converter.format($input);

is( $actual_output, $expected_output,
    'paragraphs are turned into separate <p> blocks' );

# vim:ft=perl6
