use v6;

use Test;
plan 8;

my $output_file = 'test.output';
run("rm -f $output_file");

my $html_tag
    = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'
      ~ "\n";

sub run_wiki_with_URL($url, $description = '') {
    run("./test_wiki.sh $url | grep '<html' > $output_file");
    my $expected_output = $html_tag;
    my $acutal_output   = slurp( $output_file );

    is( $acutal_output, $expected_output, $description );
}

run_wiki_with_URL('',                  'View main page');
run_wiki_with_URL('/view/Main_Page',   'View specific page');
run_wiki_with_URL('/view/Snrsdfda',    'View unexisting page');
run_wiki_with_URL('/in',               'Log in page');
run_wiki_with_URL('/out',              'Log out page');
run_wiki_with_URL('/recent',           'Recent changes');
run_wiki_with_URL('/all',              'All pages');
run_wiki_with_URL('/all?tag=november', 'All pages, specific tag');

; # RAKUDO: [perl #57876]
run("rm -r $output_file");

# vim:ft=perl6
