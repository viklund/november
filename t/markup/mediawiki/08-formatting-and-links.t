use v6;

use Test;
plan 6;
todo('not yet implemented', 6);

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = { "<a href=\"/?page=$^page\">$^page</a>" }

{
    my $input = "a[http://example.com b''c''d]e";
    my $expected_output
        = '<p>a<a href="http://example.com">b<i>c</i>d</a>e</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'italic text in a link' );
}

{
    my $input = "a[http://example.com b''c]d";
    my $expected_output
        = '<p>a<a href="http://example.com">b<i>c</i></a>d</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'mismatched italic text in a link' );
}

{
    my $input = "a[http://example.com b''''c]d";
    my $expected_output
        = '<p>a<a href="http://example.com">b<i><b>c</b></i></a>d</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output,
        'mismatched italic/bold text in a link' );
}

{
    my $input = "a[http://example.com b'''c''d]e";
    my $expected_output
        = '<p>a<a href="http://example.com">b<b>c<i>d</i></b></a>e</p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output,
        'mismatched bold/italic text in a link' );
}

{
    my $input = "a''b[http://example.com c''d]e";
    my $expected_output
        = '<p>a<i>b<a href="http://example.com">cd</a>e</i></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output,
        'in-link italic markers ignored if italic already active outside I' );
}

{
    my $input = "a''b[http://example.com c''d''e]f";
    my $expected_output
        = '<p><p>a<i>b<a href="http://example.com">cde</a>f</i></p></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output,
        'in-link italic markers ignored if italic already active outside II' );
}

# vim:ft=perl6
