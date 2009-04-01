use v6;

use Test;
plan 4;

use Dispatcher;
my $d = Dispatcher.new;

$d.add: [
    ['foo'|'bar'],    { 'First' },
    ['foo', 'a'|'b'], { 'Second' },
];

is( $d.dispatch(['foo']), 
    'First', 
    'Pattern with Junction (foo|bar) foo'  
);

is( $d.dispatch(['bar']), 
    'First', 
    'Pattern with Junction (foo|bar) bar'  
);

is( $d.dispatch(['foo', 'a']), 
    'Second', 
    'Pattern with Junction (foo/a|b) a'  
);

is( $d.dispatch(['foo', 'b']), 
    'Second', 
    'Pattern with Junction (foo/a|b) b'  
);

# vim:ft=perl6
