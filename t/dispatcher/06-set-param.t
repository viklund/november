use v6;

use Test;
plan 4;

use Dispatcher;
my $d = Dispatcher.new;

$d.add: [
    [:controller(*), :action(*) ], { 'c:' ~ $:controller ~ ' a:' ~ $:action },
    [:controller(*), / \d / ],     {  $:controller ~ '/' ~ $^a },
    [:controller(*), *, * ],       { my $c = $:controller; is($^a, $^b, 'Test within Rule') },
];

is( $d.dispatch(['one', 5]), 
    'one/5', 
    'Pattern set controller'  
);

is( $d.dispatch(['one', 'two']), 
    'c:one a:two', 
    'Pattern set controller and action'  
);

is( $d.dispatch(['Test', 3, 3]), 
    Bool::True,
    'Pattern set controller and action'  
);

# vim:ft=perl6
