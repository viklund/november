use v6;

my @tests =
[
    "Oh, how I ''italicize''." =>
    '<p>Oh, how I <i>italicize</i>.</p>',
    'italic text works',
],

[
    "Doing it ''once still produces results." =>
    "<p>Doing it <i>once still produces results.</i></p>",
    'malformed italic I',
],

[
    "But ''only until\nthe next line break." =>
    "<p>But <i>only until</i> the next line break.</p>",
    'malformed italic II',
],

[
    "Oh, how I '''embolden'''." =>
    '<p>Oh, how I <b>embolden</b>.</p>',
    'bold text works',
],

[
    "Doing it '''once still produces results." =>
    "<p>Doing it <b>once still produces results.</b></p>",
    'malformed bold I',
],

[
    "But '''only until\nthe next line break." =>
    "<p>But <b>only until</b> the next line break.</p>",
    'malformed bold II',
],

[
    "Oh, how I '''''embolden and italizice'''''." =>
    '<p>Oh, how I <b><i>embolden and italizice</i></b>.</p>',
    'italic/bold text works',
],

[
    "a''b'''c'''d''e" =>
    '<p>a<i>b<b>c</b>d</i>e</p>',
    'nested italic/bold I',
],

[
    "a'''b''c''d'''e" =>
    '<p>a<b>b<i>c</i>d</b>e</p>',
    'nested italic/bold II',
],

[
    "Doing it '''''once still produces results." =>
    "<p>Doing it <b><i>once still produces results.</i></b></p>",
    'malformed italic/bold I',
],

[
    "But '''''only until\nthe next line break." =>
    "<p>But <b><i>only until</i></b> the next line break.</p>",
    'malformed italic/bold II',
],

[
    "a''b'''c''d'''e" =>
    '<p>a<i>b<b>c</b></i><b>d</b>e</p>',
    'mis-nested italic/bold I',
],

[
    "a'''b''c'''d''e" =>
    '<p>a<b>b<i>c</i></b><i>d</i>e</p>',
    'mis-nested italic/bold II',
],

[
    "a'''b''c\nd" =>
    '<p>a<b>b<i>c</i></b> d</p>',
    'mis-nested italic/bold III',
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
