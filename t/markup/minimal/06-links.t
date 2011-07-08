use v6;

use Test;
plan 11;

use Text::Markup::Wiki::Minimal;
my $converter = Text::Markup::Wiki::Minimal.new( link_maker => &make_link);

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=link">link</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link) );

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[ link ]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=link">link</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a [[link]]</p>';
    #my $converter = Text::Markup::Wiki::Minimal.new;
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[malformed link';
    my $expected_output = '<p>An example of a [[malformed link</p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'malformed link I' );
}

{
    my $input = 'An example of a malformed link]]';
    my $expected_output = '<p>An example of a malformed link]]</p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'malformed link II' );
}

{
    my $input = 'An example of a [[My_Page]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=My_Page">My_Page</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'My_Page' );
}

{
    my $input = 'An example of a [[link boo]]';
    my $expected_output
        = '<p>An example of a <a href="?action=view&page=link">boo</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'named link' );
}

{
    my $input = 'An example of a [[http://link.org boo]]';
    my $expected_output
        = '<p>An example of a <a href="http://link.org">boo</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'named external link' );
}

{
    my $input = 'and [[http://link.org/foo-12_0.pod foo-pod 12]]';
    my $expected_output
        = '<p>and <a href="http://link.org/foo-12_0.pod">foo-pod 12</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 
        'named external link with digets and dot' );
}

{
    my $input = 'An example of a [[http://link.org boo bar baz]]';
    my $expected_output
        = '<p>An example of a <a href="http://link.org">boo bar baz</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'named (long name) external link' );
}

{
    my $input = 'An example of a [[mailto:forihrd@gmail.com ihrd]]';
    my $expected_output
        = '<p>An example of a <a href="mailto:forihrd@gmail.com">ihrd</a></p>';
    my $actual_output = $converter.format($input, :link_maker(&make_link));

    is( $actual_output, $expected_output, 'mailto' );
}

sub  make_link($page, $title?) {
    if $title {
        if $page ~~ m/':'/ {
            return "<a href=\"$page\">{$title}</a>";
        } else {
            return "<a href=\"?action=view&page=$page\">{$title}</a>";
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
    if $page ~~ 'link'|'foo'|'My_Page' {
        return True;
    } 

    return False;
}

# vim:ft=perl6
