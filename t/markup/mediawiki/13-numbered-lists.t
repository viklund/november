use v6;

my @tests =
[
    "# a\n# b\n# c" =>
    "<ol>\n<li>a</li>\n<li>b</li>\n<li>c</li>\n</ol>",
    'an ordinary numbered list'
],

[
    "# a\n\n# c" =>
    "<ol>\n<li>a</li>\n</ol>\n\n<ol>\n<li>c</li>\n</ol>",
    'an empty line creates a new list'
],

[
    "foo\n# a\n# b\nbar" =>
    "<p>foo</p>\n\n<ol>\n<li>a</li>\n<li>b</li>\n</ol>\n\n<p>bar</p>",
    'text before and after without empty lines'
],

[
    "foo\n\n# a\n# b\n\nbar" =>
    "<p>foo</p>\n\n<ol>\n<li>a</li>\n<li>b</li>\n</ol>\n\n<p>bar</p>",
    'text before and after with empty lines'
],
;

# RAKUDO: Doesn't respect "use Test :EXPORT"
use Test;
use Test::InputOutput;
plan +@tests;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
Test::InputOutput.using( { $converter.format($^input) } ).test(@tests);

# vim:ft=perl6
