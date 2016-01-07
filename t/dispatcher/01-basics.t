use v6;

use Test;
plan 9;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;

dies-ok( { $d.add: Dispatcher::Rule.new }, 
         '.add adds only complete Rule objects' );

$d.add: Dispatcher::Rule.new( :pattern(['']), code => { "Krevedko" } );

is( $d.dispatch(['']), 
    'Krevedko', 
    "Pattern ['']"
);

ok( $d.add( ['foo', 'bar'], { "Yay" } ), 
           '.add(@pattern, $code) -- shortcut for fast add Rule object' );

# RAKUDO: dispatch() returns Failure here, and rakudo gives Null PMC access
# when converting that to Bool; this works around it somehow
#nok( $d.dispatch(['foo']),
nok( $d.dispatch(['foo']) ?? True !! False, 
    'Dispatcher return False if can`t find matched Rule and do not have default' );


is( $d.dispatch(['foo', 'bar']), 
    "Yay", 
    "Dispatch to Rule ['foo', 'bar'])"
);

$d.default = { "Woow" };

is( $d.dispatch(['foo', 'bar', 'baz']), 
    "Woow", 
    'Dispatch to default, when there\'s no matched Rule'  
);

$d = Dispatcher.new( default => { "Woow" } );

is( $d.dispatch(['foo', 'bar', 'baz']), 
    "Woow", 
    'Dispatch to default created on init, when there\'s no matched Rule'  
);
# vim:ft=perl6
