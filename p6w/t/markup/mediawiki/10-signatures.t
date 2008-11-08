use v6;

use Test;
plan 3;

use Text::Markup::Wiki::MediaWiki;

my $converter = Text::Markup::Wiki::MediaWiki.new( author => 'TimToady' );

{
    my $input           = '~~~';
    my $expected_output = '<p>TimToady</p>';
    my $actual_output = $converter.format($input);

    is( $actual_output, $expected_output, 'signatures work' );
}

grammar NameAndDate {
    rule name_and_date { ^ '<p>' <name> <date> '</p>' $ }
    rule only_date { ^ '<p>' <date> '</p>' $ }
    rule name { 'TimToady' }
    rule date { \d\d:\d\d ',' \d+ \w+ \d\d\d\d '(UTC)' }
}

{
    my $input           = '~~~~';
    my $actual_output = $converter.format($input);

    ok( $actual_output ~~ NameAndDate::name_and_date,
        'signatures and dates work' );
}

{
    my $input           = '~~~~~';
    my $actual_output = $converter.format($input);

    is( $actual_output ~~ NameAndDate::only_date,
        'dates work' );
}
