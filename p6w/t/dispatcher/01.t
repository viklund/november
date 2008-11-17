use v6;

use Test;
plan 10;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;

my $r = Dispatcher::Rule.new( :name('test'), :tokens('foo', 'bar'), way => sub { return "Yay" } );
$d.add($r);

ok( ! $d.dispatch(['foo']), 'Return False if can`t find match Rule and do not have default'  );

is( $d.dispatch(['foo', 'bar']), "Yay", 'Dispatch to Rule (foo/bar)'  );

$d.default = sub { return "Woow" };

is( $d.dispatch(['foo', 'bar', 'her']), "Woow", 'Dispatch to default (foo/bar/her)'  );

my $r2 = Dispatcher::Rule.new( :name('regexp'), :tokens('foo', /^ \d+ $/), way => sub { return $^d } );
$d.add($r2);

is( $d.dispatch(['foo', '50']), '50', 'Dispatch to rule with regexp (foo/50)'  );

my $r3 = Dispatcher::Rule.new( :name('regexp2'), :tokens('foo', / \d+ /), way => sub { return ($^d + 10) } );
$d.add($r3);

is( $d.dispatch(['foo', '50']), '60', 'Dispatch to last rule when applyable two (foo/50)'  );
is( $d.dispatch(['foo', 'a50z']), '60', 'Dispatch to rule with regexp (foo/a50z)'  );

is( $d.dispatch(['foo', 'bar']), "Yay", 'Dispatch to right simple rule, just test after add more rules (foo/bar)'  );

my $r4 = Dispatcher::Rule.new( 
    :name('rgexep_inside'), 
    :tokens('foo', / \d+ /, 'bar' ), 
    way => sub { return ($^d + 1) } 
);
$d.add($r4);

is( $d.dispatch(['foo', 'item4', 'bar']), '5', 'Dispatch to rule with regexp inside (foo/item4/bar)'  );

# vim:ft=perl6
