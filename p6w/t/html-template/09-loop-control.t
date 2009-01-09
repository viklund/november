use v6;


my @tests = 
    (
    '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN><TMPL_IF NAME=!LAST>.<TMPL_ELSE>, </TMPL_IF></TMPL_LOOP>',
    FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ],
    'a, b, c.',
    '!LAST return true when current iteration is last'
    ),
    (
    '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN><TMPL_IF NAME=!FIRST>:<TMPL_ELSE>-</TMPL_IF></TMPL_LOOP>',
    FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ],
    'a:b-c-',
    '!FIRST return true when current iteration is first'
    ),
    ;

use Test;
plan +@tests / 4;


for @tests -> $tmpl, $data, $expected, $descr {
    use HTML::Template;
    my $out = HTML::Template.from_string($tmpl).with_params(hash $data).output;
    is($out, $expected, $descr);
}

# vim:ft=perl6
