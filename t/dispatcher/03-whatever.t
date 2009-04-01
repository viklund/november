use v6;
use Test;
plan 5;

use Dispatcher;

my $d = Dispatcher.new( default => { "default" } );

$d.add(
    [
        [*,],                 {  $^a  },
        [*,*],                {  $^a + $^b },
        ['foo', *],           { 'foo/' ~ $^a },
        ['foo', *, *],        { 'foo:' ~ $^a - $^b },
        ['foo', *, 'bar'],    { $^b },
    ]
);

is( $d.dispatch([42]), 42, 'Pattern *' );
is( $d.dispatch([1, 2]), 3, 'Pattern */* ' );
is( $d.dispatch(['foo', '5']), "foo/5", 'Pattern foo/*' );
is( $d.dispatch(['foo', '5', 1]), "foo:4", 'Pattern foo/*/*' );
is( $d.dispatch(['foo', 'baz', 'bar']), "baz", 'Pattern foo/*/bar' );


# vim:ft=perl6
