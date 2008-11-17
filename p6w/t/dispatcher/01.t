use v6;

use Test;
plan 2;

use Dispatcher;
ok(1,'We use Dispatcher and we are still alive');

use Dispatcher::Rule;
ok(1,'We use Dispatcher::Rule and we are still alive');

my $d = Dispatcher.new;
my $r = Dispatcher::Rule.new( :name('test'), :tokens('foo', 'bar'), way => sub { return "Yay" } );

$d.add($r);

is( $d.dispatch(['foo', 'bar']), "Yay", 'Dispatch to Rule'  );

# TODO: if I put that test first, prev die with 0 return... WTF?
ok( ! $d.dispatch(['foo']), 'Return False in can`t find match Rule and do not have default'  );


# vim:ft=perl6
