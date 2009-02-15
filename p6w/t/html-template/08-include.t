use v6;

use Test;
plan 4;

use HTML::Template;
our $*WARNINGS = 1;

my @tests = 
    [ 't/test-templates/a.tmpl',
      {},
      "AAA\n",
      'no include'],

    [ 't/test-templates/b.tmpl',
      {},
      "BBB\nCCC\n\n",
      'include one file'],

    [ 't/test-templates/bb.tmpl',
      {},
      "BBB\nCCC\n\n",
      'include one file'],

#    [ 't/test-templates/bbb.tmpl',
#      {},
#      "BBB\nCCC\n\n",
#      'include one file'],  # TODO is "" really required around the file name?

#    [ 't/test-templates/d.tmpl',
#      {},
#      "BBB\nCCC\n\n",
#      'recursive include'],  # TODO should not blow up...

#    [ 't/test-templates/e.tmpl',
#      {},
#      "EEE",
#      'missing include file'], # TODO needs warning or exception

    [ 't/test-templates/page.tmpl',
      { HEADER => "head", FOOTER => "foot"},
      "head\n\nbody\nfoot\n\n",
      'include two files'],
;

for @tests -> $t {
    my $file            = $t[0];
    my $parameters      = $t[1];
    my $expected_output = $t[2];
    my $description     = $t[3];

    #diag $file;
    my $actual_output
        #= HTML::Template.from_file($file).output();
        = HTML::Template.from_file($file).with_params(
            $parameters).output();
	#diag "'$actual_output'";
    is( $actual_output, $expected_output, $description );
}


