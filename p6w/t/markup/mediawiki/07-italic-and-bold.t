use v6;

use Test;
plan 14;

use Text__Markup__Wiki__MediaWiki;

my $converter = Text__Markup__Wiki__MediaWiki.new;

{
    my $input = "Oh, how I ''italicize''.";
    my $expected_output
        = '<p>Oh, how I <i>italicize</i>.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'italic text works' );
}

{
    my $input = "Doing it ''once still produces results.";
    my $expected_output = "<p>Doing it <i>once still produces results.</i></p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic I' );
}

{
    my $input = "But ''only until\nthe next line break.";
    my $expected_output = "<p>But <i>only until</i> the next line break.</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'malformed italic II' );
}

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
