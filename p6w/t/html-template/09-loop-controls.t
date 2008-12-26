use v6;

use HTML::Template;

my @tests = 
    (
    '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN><TMPL_IF NAME=!LAST>.<TMPL_ELSE>, </TMPL_IF></TMPL_LOOP>',
    FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ],
    'a, b, c.',
    'LAST() return true if last cicle'
    ),
    (
    '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN><TMPL_IF NAME=!FIRST>:<TMPL_ELSE>-</TMPL_IF></TMPL_LOOP>',
    FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ],
    'a:b-c-',
    'LAST() return true if last cicle'
    ),
    ;

use Test;
plan +@tests;

for @tests -> $tmpl, $data, $expected, $descr {
    say $tmpl;
    my $out = HTML::Template.from_string($tmpl).with_params(hash $data).output;
    is($out, $expected, $descr);
}

# vim:ft=perl6
