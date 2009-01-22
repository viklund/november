use v6;

use Test;
plan 8;

my $outputfile = 'test.output';
if $outputfile ~ :e {
    run("rm $outputfile");
}

{
    run("./test_wiki.sh | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'View main page' );
}

{
    run("./test_wiki.sh '/view/Main_Page' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'View specific page' );
}

{
    run("./test_wiki.sh '/view/Snrsdfda' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'View unexisting page' );
}

{
    run("./test_wiki.sh '/in' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'Log in page' );
}

{
    run("./test_wiki.sh '/out' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'Log out page' );
}

{
    run("./test_wiki.sh '/recent' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'Recent changes' );
}

{
    run("./test_wiki.sh '/all' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'All pages' );
}

{
    run("./test_wiki.sh '/all?tag=november' | grep '<html' > $outputfile");

    my $expected_output = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ~ "\n";
    my $acutal_output   = slurp( $outputfile );

    is( $acutal_output, $expected_output, 'All pages, specific tag' );
}

; # <- a parsing bug i think
if $outputfile ~ :e {
    run("rm $outputfile");
}

# vim:ft=perl6
