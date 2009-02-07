use v6;

use Test;
plan 2;
todo('not yet implemented', 2);

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new;

my $input           = 'a<br/>b<br/>c';
my $expected_output = '<p>a<br/>b<br/>c</p>';
my $actual_output = $converter.format($input);

is( $actual_output, $expected_output, '<br/> line breaks work' );

# RAKUDO: $input ~~ s{<br/>}{<br>};
$input.=trans( [ '<br/>' ] => [ '<br>' ] );
$actual_output = $converter.format($input);

is( $actual_output, $expected_output, '<br> line breaks work' );
