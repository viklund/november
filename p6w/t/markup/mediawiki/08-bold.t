use v6;

use Test;
plan 3;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = { "<a href=\"/?page=$^page\">$^page</a>" }

{
    my $input = "Oh, how I ''embolden''.";
    my $expected_output
        = '<p>Oh, how I <b>embolden</b>.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'bold text works' );
}

{
    my $input = "Doing it '''once still produces results.";
    my $expected_output = "<p>Doing it <b>once still produces results.</b></p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed bold I' );
}

{
    my $input = "But '''only until\nthe next line break.";
    my $expected_output = "<p>But <b>only until</b> the next line break.</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed bold II' );
}
