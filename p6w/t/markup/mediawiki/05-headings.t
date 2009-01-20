use v6;

use Test;
plan 4;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;

{
    my @pars =
      "==heading 1==",
      "par 1",
      "== heading 2 ==",
      "== heading 3 ==",
      "par 2";
    my $input           = join "\n\n", @pars;
    my $expected_output = join "\n\n",
       '<h2>heading 1</h2>',
       '<p>par 1</p>',
       '<h2>heading 2</h2>',
       '<h2>heading 3</h2>',
       '<p>par 2</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output,
        'mixing paragraphs and headings works' );
}

{
    # RAKUDO: heredocs
    my $input = '== Mr Heading ==
...and immediately some paragraph text.';
    my $expected_output = join "\n\n",
        '<h2>Mr Heading</h2>',
        '<p>...and immediately some paragraph text.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output,
        'really mixing paragraphs and headings works I' );
}

{
    # RAKUDO: heredocs
    my $input = 'Some text.
==Mr Surprise Heading==';
    my $expected_output = join "\n\n",
        '<p>Some text.</p>',
        '<h2>Mr Surprise Heading</h2>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output,
        'really mixing paragraphs and headings works II' );
}

{
    # RAKUDO: heredocs
    my $input = 'Paragraph.
==Heading==
Paragraph.';
    my $expected_output = join "\n\n",
        '<p>Paragraph.</p>',
        '<h2>Heading</h2>',
        '<p>Paragraph.</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output,
        'really mixing paragraphs and headings works III' );
}

# vim:ft=perl6
