use v6;

use Test;
plan 17;

use HTML::Template;

my @inputs_that_should_parse = (
    [ 'pre<TMPL_VAR NAME=BAR>post', { 'BAR' => 50 },
      'pre50post', 'simple variable insertion' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=HTML>post', { 'BAR' => '<' },
       'pre&lt;post', 'variable insertion with ESCAPE in it' ],

    [ 'pre<TMPL_VAR NAME=BAR>between<TMPL_VAR NAME=BAZ>post',
      { 'BAR' => '!', 'BAZ' => '!!' },
      'pre!between!!post', 'two variable insertions' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 1 },
       'prebarpost', 'true condition' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 0 },
      'prepost', 'false condition (because the parameter was false)' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', {},
      'prepost', 'false condition (because the parameter was not declared)' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [ { 'FOO' => 'a' }, { 'FOO' => 'b' }, { 'FOO' => 'c' } ] },
      'pre[a][b][c]post', 'a simple for loop' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [] },
      'prepost', 'an empty for loop' ],

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

    [ 'pre <TMPL_IF A>a<TMPL_ELSE>b</TMPL_IF>c<TMPL_VAR D> post',
      { 'A' => 1, 'D' => 'd' },
      'pre acd post',
      'true if/else followed by a variable insertion' ],

    [ 'pre <TMPL_IF A>a<TMPL_ELSE>b</TMPL_IF>c<TMPL_VAR D> post',
      { 'A' => 0, 'D' => 'd' },
      'pre bcd post',
      'false (but defined) if/else followed by a variable insertion' ],

    [ 'pre <tmpl_if a>a<tmpl_else>b</tmpl_if>c<tmpl_var d> post',
      { 'd' => 'd' },
      'pre bcd post',
      'false (undefined) if/else followed by a variable insertion' ],

    [ 'pre <tmpl_include name="t/test-templates/2.tmpl">post',
      { 'FOO' => 'bar' },
      'pre<h1>bar</h1>post',
      'include template' ],
);

my @inputs_that_should_not_parse = (
    [ 'pre<TMPL_IF NAME=YUCK>no tmpl_if',
      { 'YUCK' => 1 },
      'an if directive without a closing tag' ],
);

for @inputs_that_should_parse -> $test {
    # RAKUDO: List assignment not implemented yet
    my $input           = $test[0];
    my $parameters      = $test[1];
    my $expected_output = $test[2];
    my $description     = $test[3];

    # RAKUDO: Break this line with long dots.
    my $actual_output
      = HTML::Template.from_string($input).with_params(
          $parameters).output();

    is( $expected_output, $actual_output, $description );
}

for @inputs_that_should_not_parse -> $test {
    # RAKUDO: List assignment not implemented yet
    my $input           = $test[0];
    my $parameters      = $test[1];
    my $description     = $test[2];

    dies_ok( { HTML::Template.from_string($input).with_params(
               $parameters).output() }, $description );
}

my $output = HTML::Template.from_file( 't/test-templates/1.tmpl' ).with_params(
                 { 'TITLE' => 'Mmm, pie' } ).output();
is( $output, (join "\n",
                  '<html>',
                  '    <head>',
                  '        <title>Mmm, pie</title>',
                  '    </head>',
                  '    <body>',
                  '        <h1>Mmm, pie</h1>',
                  '    </body>',
                  '</html>',
                  ''),
    'reading from file' );
