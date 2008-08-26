use v6;

use Test;
plan 13;

use HTML::Template;

my @tests = (
    [ 'pre<TMPL_VAR NAME=BAR>post', { 'BAR' => 50 },
      'pre50post', 'simple TMPL_VAR' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=HTML>post', { 'BAR' => '<' },
       'pre&lt;post', 'TMPL_VAR with ESCAPE in it' ],

    [ 'pre<TMPL_VAR NAME=BAR>between<TMPL_VAR NAME=BAZ>post',
      { 'BAR' => '!', 'BAZ' => '!!' },
      'pre!between!!post', 'two TMPL_VAR' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 1 },
       'prebarpost', 'true TMPL_IF' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 0 },
      'prepost', 'false TMPL_IF (because the parameter was false)' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', {},
      'prepost', 'false TMPL_IF (because the parameter was not declared)' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [ { 'FOO' => 'a' }, { 'FOO' => 'b' }, { 'FOO' => 'c' } ] },
      'pre[a][b][c]post', 'a simple for loop' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [] },
      'prepost', 'an empty for loop' ],

    [ 'pre<TMPL_IF NAME=YUCK>no tmpl_if',
      { 'YUCK' => 1 },
      undef,
      'an if directive without a closing tag' ],

    [ '<TMPL_IF NAME=FOO>a<TMPL_IF NAME=BAR>b</TMPL_IF>c</TMPL_IF>',
      { 'FOO' => 1 },
      'ac',
      'nested if directives, inner one false' ],

    [ '<TMPL_IF NAME=FOO>a<TMPL_IF NAME=BAR>b</TMPL_IF>c</TMPL_IF>',
      { 'FOO' => 1, BAR => 1 },
      'abc',
      'nested if directives, inner one false' ],

    [
      '<TMPL_FOR FOO><TMPL_IF BAR><TMPL_VAR BAR></TMPL_IF></TMPL_FOR>',
      { FOO => [ { 'BAR' => '1' }, {}, { 'BAR' => '3' } ] },
      '13',
      'an if inside a for, with the condition set only sometimes' ],

    [ '<TMPL_FOR FOO>[<TMPL_FOR BAR><TMPL_VAR VAL></TMPL_FOR>]</TMPL_FOR>',
      { 'FOO' => [ { 'BAR' => [ map { { 'VAL' => "a$_" } }, 1..3 ] },
                   { 'BAR' => [ map { { 'VAL' => "b$_" } }, 1..4 ] },
                   { 'BAR' => [ map { { 'VAL' => "c$_" } }, 1..2 ] } ] },
      '[a1a2a3][b1b2b3b4][c1c2]',
      'nested for loops' ],
);

for @tests -> $test {
    # RAKUDO: List assignment not implemented yet
    my $input           = $test[0];
    my $parameters      = $test[1];
    my $expected_output = $test[2];
    my $description     = $test[3];

    if defined $expected_output {
        # RAKUDO: Break this line with long dots.
        my $actual_output
          = HTML::Template.from_string($input).with_params(
              $parameters).output();

        ok( $expected_output eq $actual_output, $description );
    }
    else {
        dies_ok( { HTML::Template.from_string($input).with_params(
                   $parameters).output() }, $description );
    }
}
