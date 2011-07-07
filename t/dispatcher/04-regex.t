use v6;

use Test;
plan 6;

use Dispatcher;
my $d = Dispatcher.new;
$d.add: [
    ['foo', /^ \d+ $/],          { $^d },
    [/^ \w+ $/],                 { "Yep!" if $^w ~~ Match },
    ['foo', / \d+ /],            { $^d + 10 },
    ['foo', / \d+ /, 'bar' ],    { $^d + 1 },
    ['summ', / \d+ /, / \d+ / ], { $^a + $^b },
    ['summ', / \w+ /, 1|2 ],     { $^a ~ "oo" }
];


is( $d.dispatch(['foo']),
    'Yep!',
    'Pattern with regex \w+, put Match in args'
);

is( $d.dispatch(['foo', '50']),
    '60',
    "Dispatch ['foo', '50'] to last matched Rule"
);

is( $d.dispatch(['foo', 'a50z']),
    '60',
    'Pattern with regex \d, put Match in args'
);

is( $d.dispatch(['foo', 'item4', 'bar']),
    '5',
    'Pattern with regexp in the middle (foo/\d+/bar)'
);

is( $d.dispatch(['summ', '2', '3']),
    '5',
    'Pattern with two regexs'
);

is( $d.dispatch(['summ', 'Z', '2']),
    'Zoo',
    'Pattern with regexp and junction'
);

# vim:ft=perl6
