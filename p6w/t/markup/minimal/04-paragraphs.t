use v6;

use Test;
plan 1;

use Text::Markup::Wiki::Minimal;

my $converter = Text::Markup::Wiki::Minimal.new;

my @pars =
  "par 1",
  "par 2\r\nwith\r\nnewlines in it",
  "par 3";
my $input           = join "\r\n\r\n", @pars;
my $expected_output = join "\r\n\r\n", map { "<p>$_</p>" }, @pars;
my $actual_output   = $converter.format($input);

say $expected_output;
say $actual_output;

is( $actual_output, $expected_output,
    'paragraphs are turned into separate <p> blocks' );
