use v6;

use Test;
plan 18;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;

dies_ok( { $d.add: Dispatcher::Rule.new }, 
         'Dispatch .add adds only complete Rule objects' );

$d.add: Dispatcher::Rule.new( :tokens(''), action => { "Krevedko" } );

is( $d.dispatch(['']), 
    'Krevedko', 
    "Dispatch to Rule ['']"
);

ok( $d.add( ['foo', 'bar'], { "Yay" } ), 
           '.add fith @tokens and $action -- shortcut for fast add Rule object' );

nok( $d.dispatch(['foo']), 
    'Dispatcher return False if can`t find match Rule and do not have default'  );


is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    "Dispatch to Rule ['foo', 'bar'])"
);

$d.default = { "Woow" };

is( $d.dispatch(['foo', 'bar', 'baz']), 
    "Woow", 
    'Dispatch to default, when have no matched Rule'  
);

$d.add: ['foo', 'a'|'b'], { "Zzzz" };

is( $d.dispatch(['foo', 'a']), 
    'Zzzz', 
    'Dispatch to Rule with Junction a'  
);

is( $d.dispatch(['foo', 'b']), 
    'Zzzz', 
    'Dispatch to Rule with Junction (foo/a|b) b'  
);

$d.add: ['foo', /^ \d+ $/], { $^d };

is( $d.dispatch(['foo', '50']), 
    '50', 
    "Dispatch to Rule with regexp ['foo', /^ \d+ \$/])"  
);

$d.add( [/^ \w+ $/], { "Yep!" if $^w.WHAT eq 'Match' } );

is( $d.dispatch(['so']), 
    'Yep!', 
    "Argument is Match"
);

$d.add: ['foo', / \d+ /], { $^d + 10 };

is( $d.dispatch(['foo', '50']), 
    '60', 
    "Dispatch ['foo', '50'] to last matched Rule" 
);

is( $d.dispatch(['foo', 'a50z']), 
    '60', 
    'Rule that catches the right arg'  
);

$d.add: ['foo', / \d+ /, 'bar' ], { $^d + 1 };

is( $d.dispatch(['foo', 'item4', 'bar']), 
    '5', 
    'Rule with regexp in the middle (foo/\d+/bar)'
);

$d.add: ['summ', / \d+ /, / \d+ / ], { $^a + $^b };


is( $d.dispatch(['summ', '2', '3']), 
    '5', 
    'Dispatch to Rule with two regexps'
);

$d.add: ['summ', / \w+ /, 1|2 ], { $^a ~ "oo" };

is( $d.dispatch(['summ', 'Z', '2']), 
    'Zoo', 
    'Rule with a regexp and a junction'
);

is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    'Dispatch to simple Rule, test after adding so many Rules' 
);

# vim:ft=perl6
