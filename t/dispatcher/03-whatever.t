use v6;
use Test;
plan 5;

use Dispatcher;

my $d = Dispatcher.new( default => { "default" } );

$d.add_rules(
    [
        [*,],                 {  $^a  },
        [*,*],                {  $^a + $^b },
        ['foo', *],           { 'foo/' ~ $^a },
        ['foo', *, *],           { 'foo:' ~ $^a - $^b },
        ['foo', *, 'bar'],    { $^b },
    ]
);

is( $d.dispatch([42]), 42, 'Use pattern *' );
is( $d.dispatch([1, 2]), 3, 'Use pattern */* ' );
is( $d.dispatch(['foo', '5']), "foo/5", 'Use pattern foo/*' );
is( $d.dispatch(['foo', '5', 1]), "foo:4", 'Use pattern foo/*/*' );
is( $d.dispatch(['foo', 'baz', 'bar']), "baz", 'Use pattern foo/*/bar' );


# vim:ft=perl6
