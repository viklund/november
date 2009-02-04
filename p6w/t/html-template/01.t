use v6;

use Test;
plan 28;

use HTML::Template;

my @inputs_that_should_parse =
    [ 'foo', {},
      'foo', 'plain text' ],

    [ qq|<body>plain <a href="link">link</a>\n text</body>|, {},
      qq|<body>plain <a href="link">link</a>\n text</body>|, 'simple HTML' ],

    [ 'pre<TMPL_VAR NAME=BAR>post', { 'BAR' => 50 },
      'pre50post', 'simple variable insertion' ],

    [ 'pre<title><TMPL_VAR NAME=BAR></title>post', { 'BAR' => 50 },
      'pre<title>50</title>post', 'simple variable insertion in html' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=NONE>post', { 'BAR' => 'YaY' },
       'preYaYpost', 'variable insertion with NONE  escape' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=HTML>post', { 'BAR' => '<' },
       'pre&lt;post', 'variable insertion with HTML escape' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=URL>post', { 'BAR' => ' ' },
       'pre+%20+post', 'variable insertion with URL escape' ],

    [ 'pre<TMPL_VAR BAR ESCAPE=URI>post', { 'BAR' => ' ' },
       'pre+%20+post', 'variable insertion with URI escape' ],

    [ 'pre<TMPL_VAR NAME=BAR>between<TMPL_VAR NAME=BAZ>post',
      { 'BAR' => '!', 'BAZ' => '!!' },
      'pre!between!!post', 'two variable insertions' ],

    # 10
    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 1 },
       'prebarpost', 'true condition' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', { 'FOO' => 0 },
      'prepost', 'false condition (because the parameter was false)' ],

    [ 'pre<TMPL_IF NAME=FOO>bar</TMPL_IF>post', {},
      'prepost', 'false condition (because the parameter was not declared)' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [ { 'FOO' => 'a' }, { 'FOO' => 'b' }, { 'FOO' => 'c' } ] },
      'pre[a][b][c]post', 'a simple for loop' ],

    [ 'pre<TMPL_IF NAME=BLUBB><TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR></TMPL_IF>post',
      { 'BLUBB' => [ { 'FOO' => 'a' }, { 'FOO' => 'b' }, { 'FOO' => 'c' } ] },
      'pre[a][b][c]post', 'a simple for loop in if' ],

    [ 'pre<TMPL_FOR NAME=BLUBB>[<TMPL_VAR FOO>]</TMPL_FOR>post',
      { 'BLUBB' => [] },
      'prepost', 'an empty for loop' ],

    # this doesn't work in p5 version by default, but it's useful for us,
    # and it DWIMs
    [ 'pre<TMPL_FOR NAME=FOO>[<TMPL_VAR a><TMPL_VAR BAR>]</TMPL_FOR>post',
      { FOO => [{a => 1}, {a => 2}], BAR => 'Y' },
      'pre[1Y][2Y]post', 'an empty for loop' ],

    [ '<TMPL_IF NAME=FOO>a<TMPL_IF NAME=BAR>b</TMPL_IF>c</TMPL_IF>',
      { 'FOO' => 1 },
      'ac',
      'nested if directives, inner one false' ],

    [ '<TMPL_IF NAME=FOO>a<TMPL_IF NAME=BAR>b</TMPL_IF>c</TMPL_IF>',
      { 'FOO' => 1, BAR => 1 },
      'abc',
      'nested if directives, all true' ],

    [ '<TMPL_IF NAME=FOO>a<TMPL_VAR NAME=FOO>c</TMPL_IF>',
      { 'FOO' => 'YaY' },
      'aYaYc',
      'if derictives and insertion directive' ],

    # 20
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

    [ 'pre <TMPL_IF A>a<TMPL_ELSE>b</TMPL_IF>c<TMPL_VAR d> post',
      { 'd' => 'd' },
      'pre bcd post',
      'false (undefined) if/else followed by a variable insertion' ],

    [ 'pre<TMPL_INCLUDE NAME="t/test-templates/2.tmpl">post',
      { 'FOO' => 'bar' },
      "pre<h1>bar</h1>\npost",
      'include template' ],

    [ '<TMPL_LOOP NAME=FOO>:)</TMPL_LOOP>',
      { 'FOO' => [ { :BAR } ] },
      ":)",
      'we can use TMPL_LOOP as TMPL_FOR' ],
;

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

    is( $actual_output, $expected_output, $description );
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

# vim:ft=perl6
