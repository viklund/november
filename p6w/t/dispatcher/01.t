use v6;

use Test;
plan 15;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;

dies_ok( { $d.add: Dispatcher::Rule.new }, 
         'Dispatch add only complite Rule object' );

$d.add: Dispatcher::Rule.new( :tokens('foo', 'bar'), way => { "Yay" } );

nok( $d.dispatch(['foo']), 
    'Return False if can`t find match Rule and do not have default'  );

is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    'Dispatch to Rule (foo bar)'
);

$d.default = sub { return "Woow" };

is( $d.dispatch(['foo', 'bar', 'her']), 
    "Woow", 
    'Dispatch to default'  
);

$d.add: Dispatcher::Rule.new( :tokens('foo', 'a'|'b'), way => { "Zzzz" } );

is( $d.dispatch(['foo', 'a']), 
    'Zzzz', 
    'Dispatch to rule with Junction (foo/a|b) a'  
);

is( $d.dispatch(['foo', 'b']), 
    'Zzzz', 
    'Dispatch to rule with Junction (foo/a|b) b'  
);

$d.add: Dispatcher::Rule.new( :tokens('foo', /^ \d+ $/), way => { $^d } );

is( $d.dispatch(['foo', '50']), 
    '50', 
    'Dispatch to rule with regexp (foo/50)'  
);

$d.add: Dispatcher::Rule.new( :tokens('foo', / \d+ /), way => { $^d + 10 } );

is( $d.dispatch(['foo', '50']), 
    '60', 
    'Dispatch to last rule when applyable two (foo/50)'  
);

is( $d.dispatch(['foo', 'a50z']), 
    '60', 
    'Rule with regexp (foo/a50z)'  
);

is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    'Dispatch to simple Rule, test after add more rules (foo/bar)' 
);

$d.add: Dispatcher::Rule.new( :tokens('foo', / \d+ /, 'bar' ), 
                              way => { $^d + 1 } );

is( $d.dispatch(['foo', 'item4', 'bar']), 
    '5', 
    'Rule with regexp in center (foo/\d+/bar)'
);

$d.add: Dispatcher::Rule.new( :tokens('summ', / \d+ /, / \d+ / ), 
                              way => { $^a + $^b } );


is( $d.dispatch(['summ', '2', '3']), 
    '5', 
    'Rule with two regexp (summ/\d+/\d+)'
);


is( $d.dispatch(['summ', '12', '23']), 
    '35', 
    'Rule with two regexp again (summ/\d+/\d+)'
);

#lives_ok ( { $d.add( ['boo'], { "A-a-a" } ) }, 'Add Rule object shortcut' );

# vim:ft=perl6
