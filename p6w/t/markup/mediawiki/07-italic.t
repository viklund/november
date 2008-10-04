use v6;

use Test;
plan 3;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = { "<a href=\"/?page=$^page\">$^page</a>" }

{
    my $input = "Oh, how I ''italicize''.";
    my $expected_output
        = '<p>Oh, how I <i>italicize</i>.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'italic text works' );
}

{
    my $input = "Doing it ''once still produces results.";
    my $expected_output = "<p>Doing it <i>once still produces results.</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic I' );
}

{
    my $input = "But ''only until\nthe next line break.";
    my $expected_output = "<p>But <i>only</i> until the next line break.</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic II' );
}
