use v6;

use Test;
plan 11;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;
my $link_maker = {
    my $l = $^page.tc;
    my $t = $^title // $^page;
    $l .= subst(' ', '_', :g);
    qq[<a href="/?page=$l">{$t}</a>];
}
my $extlink_maker = -> $href, $title {
    qq[<a href="$href">{$title}</a>]
}

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="/?page=Link">link</a></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, '[[link]] conversion works' );
}

{
    my $input = 'An example of a [[ link ]]';
    my $expected_output
        = '<p>An example of a <a href="/?page=Link">link</a></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, '[[ link ]] conversion works' );
}

{
    my $input = 'An example of a [[link]]';
    my $expected_output = '<p>An example of a [[link]]</p>';
    my $actual_output = $converter.format($input);

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
    my $input = "[[Link with spaces]]";
    my $expected_output = '<p><a href="/?page=Link_with_spaces">Link with spaces</a></p>';
    my $actual_output = $converter.format($input, :$link_maker);

    is( $actual_output, $expected_output, 'link with spaces' );
}

{
    my $input = 'This is an [http://example.com] external link';
    my $expected_output
        = '<p>This is an <a href="http://example.com">http://example.com</a> '
          ~ 'external link</p>';
    my $actual_output = $converter.format($input, :$extlink_maker);

    is( $actual_output, $expected_output, 'external link I' );
}

{
    my $input = 'This is an [ http://example.com ] external link';
    my $expected_output
        = '<p>This is an <a href="http://example.com">http://example.com</a> '
          ~ 'external link</p>';
    my $actual_output = $converter.format($input, :$extlink_maker);

    is( $actual_output, $expected_output, 'external link I with whatespaces' );
}

{
    my $input = 'This is an [http://example.com external link with a title]';
    my $expected_output
        = '<p>This is an <a href="http://example.com">external link with a '
          ~ 'title</a></p>';
    my $actual_output = $converter.format($input, :$extlink_maker);

    is( $actual_output, $expected_output, 'external link II' );
}

{
    my $input = 'This is an [http://example.com] external link';
    my $expected_output = "<p>{$input}</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'no extlink maker, no conversion' );
}

# vim:ft=perl6
