use v6;

use Test;
plan 1;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;

my @pars =
  "==heading 1==",
  "par 1",
  "== heading 2 ==",
  "== heading 3 ==",
  "par 2";
my $input           = join "\n\n", @pars;
my $expected_output = join "\n\n",
   '<h2>heading 1</h2>',
   '<p>par 1</p>',
   '<h2>heading 2</h2>',
   '<h2>heading 3</h2>',
   '<p>par 2</p>';
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, 'mixing paragraphs and headings works' );
