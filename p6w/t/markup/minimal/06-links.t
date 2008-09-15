use v6;

use Test;
plan 3;

use Text::Markup::Wiki::Minimal;

my $converter = Text::Markup::Wiki::Minimal.new;

class MockedWiki {
    method make_link($page) { return "<a href=\"/?page=$page\">$page</a>"; }
}

$converter.wiki = MockedWiki.new;

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="/?page=link">link</a></p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[malformed link';
    my $expected_output = '<p>An example of a [[malformed link</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed link I' );
}

{
    my $input = 'An example of a malformed link]]';
    my $expected_output = '<p>An example of a malformed link]]</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed link II' );
}
