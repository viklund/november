use v6;

use Test;
plan 6;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = { my $l = $^page.ucfirst; "<a href=\"/?page=$l\">$^page</a>" }

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="/?page=Link">link</a></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[link]]';
    my $expected_output = '<p>An example of a [[link]]</p>';
    my $actual_output = $converter.format($input);
    say $actual_output, "|", $expected_output;

    is( $actual_output, $expected_output, 'no link maker, no conversion' );
}

{
    my $input = 'An example of a [[malformed link';
    my $expected_output = '<p>An example of a [[malformed link</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'malformed link I' );
}

{
    my $input = 'An example of a malformed link]]';
    my $expected_output = '<p>An example of a malformed link]]</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'malformed link II' );
}

{
    my $input = "[[A Link\nSpanning Two Lines]]";
    my $expected_output = '<p>[[A Link Spanning Two Lines]]</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'malformed link III' );
}

{
    my $input = 'This is an [http://example.com] external link';
    my $expected_output
        = '<p>This is an <a href="http://example.com" external link</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'external link' );
}

# vim:ft=perl6
