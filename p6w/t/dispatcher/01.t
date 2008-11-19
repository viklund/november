use v6;

use Test;
plan 18;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;

dies_ok( { $d.add: Dispatcher::Rule.new }, 
         'Dispatch .add add only complite Rule object' );

$d.add: Dispatcher::Rule.new( :tokens(''), way => { "Krevedko" } );

is( $d.dispatch(['']), 
    'Krevedko', 
    "Dispatch to Rule ['']"
);

ok( $d.add_rule( ['foo', 'bar'], { "Yay" } ), 
           'Dispatch .add_rule -- shortcut for fast add Rule object' );

nok( $d.dispatch(['foo']), 
    'Dispatcher return False if can`t find match Rule and do not have default'  );


is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    "Dispatch to Rule ['foo', 'bar'])"
);

$d.default = { "Woow" };

is( $d.dispatch(['foo', 'bar', 'her']), 
    "Woow", 
    'Dispatch to default, when have no matched Rule'  
);

$d.add_rule: ['foo', 'a'|'b'], { "Zzzz" };

is( $d.dispatch(['foo', 'a']), 
    'Zzzz', 
    'Dispatch to Rule with Junction a'  
);

is( $d.dispatch(['foo', 'b']), 
    'Zzzz', 
    'Dispatch to Rule with Junction (foo/a|b) b'  
);

$d.add_rule: ['foo', /^ \d+ $/], { $^d };

is( $d.dispatch(['foo', '50']), 
    '50', 
    "Dispatch to Rule with regexp ['foo', /^ \d+ $/])"  
);

$d.add_rule( [/^ \w+ $/], { "Yep!" if $^w.WHAT eq 'Match' } );

is( $d.dispatch(['so']), 
    'Yep!', 
    "Argument is Match"
);

$d.add_rule: ['foo', / \d+ /], { $^d + 10 };

is( $d.dispatch(['foo', '50']), 
    '60', 
    "Dispatch ['foo', '50'] to last matched Rule" 
);

is( $d.dispatch(['foo', 'a50z']), 
    '60', 
    'Rule catch right arg'  
);

$d.add_rule: ['foo', / \d+ /, 'bar' ], { $^d + 1 };

is( $d.dispatch(['foo', 'item4', 'bar']), 
    '5', 
    'Rule with regexp in center (foo/\d+/bar)'
);

$d.add_rule: ['summ', / \d+ /, / \d+ / ], { $^a + $^b };


is( $d.dispatch(['summ', '2', '3']), 
    '5', 
    'Dispatch to Rule with two regexp'
);

$d.add_rule: ['summ', / \w+ /, 1|2 ], { $^a ~ "oo" };

is( $d.dispatch(['summ', 'Z', 2]), 
    'Zoo', 
    'Rule with regexp and junction'
);

is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    'Dispatch to simple Rule, test after add so many Rules' 
);

# vim:ft=perl6
