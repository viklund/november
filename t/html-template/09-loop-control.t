use v6;

use Test;
plan 2;

use HTML::Template;

{
    my $data = (FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ]);
    my $out = HTML::Template.from_string(
                  '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN>'
                ~ '<TMPL_IF NAME=!LAST>.<TMPL_ELSE>, </TMPL_IF></TMPL_LOOP>'
              ).with_params(hash $data).output;
    my $expected = 'a, b, c.';
    is($out, $expected, '!LAST returns true on the last iteration');
}

{
    my $data = (FOO => [ {IN => 'a'}, {IN => 'b'}, {IN => 'c'} ]);
    my $out = HTML::Template.from_string(
                  '<TMPL_LOOP NAME=FOO><TMPL_VAR NAME=IN>'
                ~ '<TMPL_IF NAME=!FIRST>:<TMPL_ELSE>-</TMPL_IF></TMPL_LOOP>'
              ).with_params(hash $data).output;
    my $expected = 'a:b-c-';
    is($out, $expected, '!FIRST returns true on the first iteration');
}

# vim:ft=perl6
