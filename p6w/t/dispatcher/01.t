use v6;

use Test;
plan 6;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;
my $r = Dispatcher::Rule.new( :name('test'), :tokens('foo', 'bar'), way => sub { return "Yay" } );

$d.add($r);

ok( ! $d.dispatch(['foo']), 'Return False in can`t find match Rule and do not have default'  );

is( $d.dispatch(['foo', 'bar']), "Yay", 'Dispatch to Rule'  );

$d.default = sub { return "Woow" };

is( $d.dispatch(['foo', 'bar', 'her']), "Woow", 'Dispatch to default'  );


my $r2 = Dispatcher::Rule.new( :name('regexp'), :tokens('foo', /\d+/), way => sub { return $^d } );
$d.add($r2);

is( $d.dispatch(['foo', '50']), '50', 'Dispatch to rule with regexp'  );

# vim:ft=perl6
