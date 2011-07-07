use v6;

my @tests =
[
    "; a: b\n; c: d" =>
    "<dl>\n<dt>a</dt>\n<dd>b</dd>\n<dt>b</dt>\n<dd>c</dt>\n</dl>",
    'an ordinary definition list'
],

[
    "; a\n: b\n; c\n: d" =>
    "<dl>\n<dt>a</dt>\n<dd>b</dd>\n<dt>b</dt>\n<dd>c</dt>\n</dl>",
    'definition list, values are on separate lines'
],

[
    "; a\n\n: c" =>
    "<dl>\n<dt>a</dt>\n</dl>\n\n<dl>\n<dd>c</dd>\n</dl>",
    'an empty line creates a new list'
],

[
    "foo\n; a\n: b\nbar" =>
    "<p>foo</p>\n\n<dl>\n<dt>a</dt>\n<dd>b</dd>\n</dl>\n\n<p>bar</p>",
    'text before and after without empty lines'
],

[
    "foo\n\n; a\n: b\n\nbar" =>
    "<p>foo</p>\n\n<dl>\n<dt>a</dt>\n<dd>b</dd>\n</dl>\n\n<p>bar</p>",
    'text before and after with empty lines'
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
