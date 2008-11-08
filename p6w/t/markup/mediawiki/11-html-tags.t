use v6;

use Test;
plan 52;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new();

# actually, this needs to be rethought a bit. <p>...</p> must be specially
# handled, for example. also, ol, ul, table, the headings, blockquote.
for <b big blockquote caption center cite code dd div dl dt em font
     h1 h2 h3 h4 h5 h6 hr i li ol p pre rb rp rt ruby s small strike
     strong sub sup table td th tr tt u ul var> -> $tag {

    my $input = "before<$tag>inside</$tag>after";
    my $expected_output = "<p>$input</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, "<$tag>..</$tag> gets through" );
}

for <abbr acronym q kbd samp del ins object> -> $tag {

    my $input = "before<$tag>inside</$tag>after";
    my $expected_output = "<p>before&lt;$tag&gt;inside&lt;/$tag&gt;after</p>";
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, "<$tag>..</$tag> doesn't get through");
}

my $input = "before<!-- inside -->after";
my $expected_output = "<p>$input</p>";
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, "<!-- comments --> get through");
