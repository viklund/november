use v6;

my @tests =
[
    "* a\n** a1\n* b" =>
    "<ul>\n<li>a\n<ul>\n<li>a1</li>\n</ul>\n</li>\n<li>b</li>\n</ul>",
    'a list inside a list'
],

[
    "* a\n*; a1: a2\n* b" =>
    "<ul>\n<li>a\n"
    ~ "<dl>\n<dt>a1</dt>\n<dd>a2</dd>\n</dl>\n</li>\n<li>b</li>\n</ul>",
    'a definition list inside a bullet list'
],

[
    "*:##; OH HAI" =>
    "<ul>\n<li>\n<dl>\n<dt>\n<ol>\n<li>\n<ol>\n<li>\n<dl>\n<dd>OH HAI</dd>"
    ~ "\n</dl>\n</ol>\n</ol>\n</dl>\n</ul>",
    'deep nesting'
],
;

# RAKUDO: Doesn't respect "use Test :EXPORT"
use Test;
use Test::InputOutput;
plan +@tests;

todo('not implemented yet', +@tests);

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
Test::InputOutput.using( { $converter.format($^input) } ).test(@tests);

# vim:ft=perl6
