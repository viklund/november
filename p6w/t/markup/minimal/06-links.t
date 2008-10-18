use v6;

use Test;
plan 7;

use Text__Markup__Wiki__Minimal;


my $converter = Text__Markup__Wiki__Minimal.new( link_maker => &make_link);

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=link">link</a></p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a [[link]]</p>';
    my $converter = Text__Markup__Wiki__Minimal.new;
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

{
    my $input = 'An example of a [[link boo]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=link">boo</a></p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'named link' );
}

{
    my $input = 'An example of a [[http://link.org boo]]';
    my $expected_output
        = '<p>An example of a <a href="http://link.org">boo</a></p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'named external link' );
}

{
    my $input = 'An example of a [[http://link.org boo bar baz]]';
    my $expected_output
        = '<p>An example of a <a href="http://link.org">boo bar baz</a></p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'named (long name) external link' );
}

sub  make_link($page, $title?) {
    if $title {
        if $page ~~ m/':'/ {
            return "<a href=\"$page\">$title</a>";
        } else {
            return "<a href=\"?action=view&page=$page\">$title</a>";
        }
        
    } else {
        return sprintf('<a href="?action=%s&page=%s"%s>%s</a>',
                       wiki_page_exists($page)
                         ?? ('view', $page, '')
                         !! ('edit', $page, ' class="nonexistent"'),
                       $page);
    }
}

sub wiki_page_exists ($page) {
    if $page ~~ 'link' | 'foo' {
        return True;
    } 

    return False;
}
