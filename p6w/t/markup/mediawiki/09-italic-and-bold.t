use v6;

use Test;
plan 8;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = { "<a href=\"/?page=$^page\">$^page</a>" }

{
    my $input = "Oh, how I '''''embolden and italizice'''''.";
    # It could be either way here, but let's just arbritarily assume that
    # it'll be <i><b></b></i>
    my $expected_output
        = '<p>Oh, how I <i><b>embolden and italizice</b></i>.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'italic/bold text works' );
}

{
    my $input = "a''b'''c'''d''e";
    my $expected_output = '<p>a<i>b<b>c</b>d</i>e</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'nested italic/bold I');
}

{
    my $input = "a'''b''c''d'''e";
    my $expected_output = '<p>a<b>b<i>c</i>d</b>e</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'nested italic/bold II');
}

{
    my $input = "Doing it '''''once still produces results.";
    my $expected_output
        = "<p>Doing it <i><b>once still produces results.</b></i></p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic/bold I' );
}

{
    my $input = "But '''''only until\nthe next line break.";
    my $expected_output
        = "<p>But <i><b>only until</b></i> the next line break.</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic/bold II' );
}

{
    my $input = "a''b'''c''d'''e";
    my $expected_output = '<p>a<i>b<b>c</b></i><b>d</b>e</p>';

    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'mis-nested italic/bold I' );
}

{
    my $input = "a'''b''c'''d''e";
    my $expected_output = '<p>a<b>b<i>c</i></b><i>d</i>e</p>';

    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'mis-nested italic/bold II' );
}

{
    my $input = "a'''b''c\nd";
    my $expected_output = '<p>a<b>b<i>c</i></b> d</p>';

    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'mis-nested italic/bold III' );
}
